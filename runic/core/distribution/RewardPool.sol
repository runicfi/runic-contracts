// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../lib/AccessControlConstants.sol";
import "../interfaces/IRewardPool.sol";

abstract contract RewardPool is AccessControlEnumerable, ReentrancyGuard, IRewardPool {
    using SafeERC20 for IERC20;
    bytes32 public constant BOOST_OPERATOR = keccak256("BOOST_OPERATOR"); // 0123effceab9407b7c1359adb00dd1e7c8552c85d6adec1a0d21f3c17c8785d1

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many tokens the user has provided.
        uint256 rewardDebt;         // Reward debt. any point in time, the amount of rewardToken entitled to a user but is pending to be distributed is:
                                    // pending reward = (user share * pool.accRewardPerShare) - user.rewardDebt
                                    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
                                    // 1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
                                    // 2. User receives the pending reward sent to his/her address.
                                    // 3. User's `amount` gets updated. Pool's `totalBoostedShare` gets updated.
                                    // 4. User's `rewardDebt` gets updated.
        uint256 boostMultiplier;    // user boost multiplier
        uint256 lastDepositTime;    // keep track of deposit time for potential penalty.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;               // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. RewardToken to distribute in the pool.
        uint256 lastRewardTime;     // Last time rewardToken that rewardToken distribution occurs.
        uint256 accRewardPerShare;  // Accumulated rewardToken per share, times 1e18. See below.
        uint256 totalBoostedShare;  // The total amount of user shares in each pool. After considering the share boosts.
        uint256 depositFee;         // depositFee in 10000 basis point. 50 = 0.5%
        uint256 lockTime;           // time to lock deposits
        bool isStarted;             // if lastRewardBlock has passed
    }

    address public feeAddress;
    address public override reward; // rewardToken
    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo; // Info of each user that stakes LP tokens.
    uint256 public override totalAllocPoint; // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public startTime; // Time when rewardToken starts
    uint256 public endTime; // Time when rewardToken ends
    uint256 public lastTimeUpdateRewardRate;
    uint256 public accumulatedRewardPaid;
    uint256 public rewardPerSecond;
    uint256 public totalRewards;
    uint256 public constant MAX_DEPOSIT_FEE = 400; // max deposit fee of 4%
    uint256 public constant MAX_LOCK_TIME = 30 days; // max time a pool can set lock time
    uint256 public constant MAX_REWARD_PER_SECOND = 10 ether; // max reward per second
    uint256 public constant REWARD_PRECISION = 1e18;
    uint256 public constant BOOST_PRECISION = 1e10; // replace this for different precision

    event AddPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    event UpdateBoostMultiplier(address indexed user, uint256 pid, uint256 oldMultiplier, uint256 newMultiplier);
    event IncreaseRewardBalance(uint256 amount);
    event UpdateRewardRate(uint256 rewardRate, uint256 endTime);

    error ExistingPool(uint256);    // 0xdad63dda
    error Late();                   // 0x86ceaa08
    error Locked();                 // 0x0f2e5b6c
    error MaxDepositFee();          // 0x45f7e0bf
    error MaxLockTime();            // 0x7326cd6e
    error NotBoostOperator();       // 0x9ab37c92
    error NotOperator();            // 0x7c214f04
    error RewardToken();            // 0xf1e9f1e5
    error Token();                  // 0xc2412676
    error TooHigh();                // 0xf2034b4e
    error TooLow();                 // 0x3ca55442
    error ZeroAddress();            // 0xd92e233d

    /**
     * @notice This should be override to adjust for pool's settings
     */
    constructor(address rewardToken_, address feeAddress_, uint256 startTime_) {
        if(block.timestamp > startTime_) revert Late();
        reward = rewardToken_;
        feeAddress = feeAddress_;
        startTime = startTime_;
        endTime = startTime_ + 7 days;
        totalRewards = 50000 ether;
        rewardPerSecond = totalRewards / 7 days;
        lastTimeUpdateRewardRate = startTime_;
        AccessControl._grantRole(AccessControl.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    /**
     * @notice Throws if caller is not the boost operator.
     */
    modifier onlyBoostOperator() {
        if(!AccessControl.hasRole(BOOST_OPERATOR, msg.sender)) revert NotBoostOperator();
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IRewardPool).interfaceId;
    }

    /**
     * @notice Allows for change after deployment of contract but before startTime.
     * This function should be override to adjust for endTime if any
     * @param startTime_ cannot be changed once startTime is met
     */
    function setStartTime(uint256 startTime_) external virtual onlyOperator {
        if(block.timestamp > startTime || block.timestamp > startTime_) revert Late();
        startTime = startTime_;
        endTime = startTime_ + 7 days;
        lastTimeUpdateRewardRate = startTime_;
        // go through each existing pool and update lastRewardTime if it is less
        uint256 length = poolInfo.length;
        for(uint256 pid; pid < length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            if(pool.lastRewardTime < startTime_) pool.lastRewardTime = startTime_;
        }
    }

    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 pid_) external view override returns (address token_, uint256 allocPoint_) {
        PoolInfo memory pool = poolInfo[pid_];
        token_ = address(pool.token);
        allocPoint_ = pool.allocPoint;
    }

    function getRewardPerSecond() external view virtual override returns (uint256) {
        return rewardPerSecond;
    }

    /**
     * @notice Checks for duplicate deposit tokens. no pool should have the same deposit token
     * @param token_ Address of IERC20 token
     */
    function checkPoolDuplicate(IERC20 token_) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; pid++) {
            if(poolInfo[pid].token == token_) revert ExistingPool(pid);
        }
    }

    /**
     * @notice Add a new token to the pool. Can only be called by the owner.
     * @param allocPoint_ Number of allocation points for the new pool.
     * @param token_ Address of IERC20 token. Must not be the same as reward token unless reward token is minted from this contract
     * @param lastRewardTime_ The last time for reward to start. Cannot be less than startTime or current time. Can be greater than current time
     * @param depositFee_ The deposit fee
     * @param lockTime_ The time to lock deposits
     * @param withUpdate_ Whether call "massUpdatePools" operation
     */
    function add(uint256 allocPoint_, IERC20 token_, uint256 lastRewardTime_, uint256 depositFee_, uint256 lockTime_, bool withUpdate_) external virtual onlyOperator {
        if(depositFee_ > MAX_DEPOSIT_FEE) revert MaxDepositFee();
        if(lockTime_ > MAX_LOCK_TIME) revert MaxLockTime();
        if(address(token_) == reward) revert RewardToken(); // remove this if contract mints reward instead
        checkPoolDuplicate(token_);
        if(withUpdate_) {
            massUpdatePools();
        }
        if (block.timestamp < startTime) {
            if (lastRewardTime_ < startTime) {
                lastRewardTime_ = startTime;
            }
        } else {
            if (lastRewardTime_ < block.timestamp) {
                lastRewardTime_ = block.timestamp;
            }
        }
        bool isStarted_ = (lastRewardTime_ <= startTime) || (lastRewardTime_ <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : token_,
            allocPoint : allocPoint_,
            lastRewardTime : lastRewardTime_,
            accRewardPerShare : 0,
            totalBoostedShare : 0,
            depositFee : depositFee_,
            lockTime: lockTime_,
            isStarted : isStarted_
        }));
        if (isStarted_) {
            totalAllocPoint += allocPoint_;
        }
        emit AddPool(poolInfo.length - 1, allocPoint_, token_);
    }

    /**
     * @notice Update the given pool's rewardToken allocation point. Can only be called by the owner.
     * @param pid_ The id of the pool
     * @param allocPoint_ New number of allocation points for the pool
     * @param withUpdate_ Whether call "massUpdatePools" operation.
     */
    function set(uint256 pid_, uint256 allocPoint_, bool withUpdate_) external virtual onlyOperator {
        // No matter withUpdate_ is true or false, we need to execute updatePool once before set the pool parameters.
        updatePool(pid_);

        if(withUpdate_) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfo[pid_];
        if (pool.isStarted) {
            totalAllocPoint = (totalAllocPoint - pool.allocPoint) + allocPoint_;
        }
        pool.allocPoint = allocPoint_;
        emit SetPool(pid_, allocPoint_);
    }

    /**
     * @notice Resets pool's lastRewardTime (startTime)
     * @param pid_ The id of the pool
     * @param startTime_ The new start time of pool
     */
    function resetPoolStartTime(uint256 pid_, uint256 startTime_) external virtual onlyOperator {
        PoolInfo storage pool = poolInfo[pid_];
        if(pool.lastRewardTime <= block.timestamp) revert Late();
        if (pool.isStarted) {
            pool.isStarted = false;
            totalAllocPoint -= pool.allocPoint;
        }
        pool.lastRewardTime = startTime_;
    }

    /**
     * @notice Updates the deposit fee of a pool
     * @param pid_ The id of the pool
     * @param depositFee_ The deposit fee
     */
    function updatePoolDepositFee(uint256 pid_, uint256 depositFee_) external virtual onlyOperator {
        if(depositFee_ > MAX_DEPOSIT_FEE) revert MaxDepositFee();
        poolInfo[pid_].depositFee = depositFee_;
    }

    /**
     * @notice Updates the lock time of a pool
     * @param pid_ The id of the pool
     * @param lockTime_ The lock time
     */
    function updatePoolLockTime(uint256 pid_, uint256 lockTime_) external virtual onlyOperator {
        if(lockTime_ > MAX_LOCK_TIME) revert MaxLockTime();
        poolInfo[pid_].lockTime = lockTime_;
    }

    /**
     * @notice Return accumulate rewards over the given fromTime_ to toTime_
     * Override this if there is no endTime
     */
    function getGeneratedReward(uint256 fromTime_, uint256 toTime_) public view virtual returns (uint256) {
        if (fromTime_ >= toTime_) return 0;
        if (toTime_ >= endTime) {
            if (fromTime_ >= endTime) return 0;
            if (fromTime_ <= startTime) return (endTime - startTime) * rewardPerSecond;
            return (endTime - fromTime_) * rewardPerSecond;
        } else {
            if (toTime_ <= startTime) return 0;
            if (fromTime_ <= startTime) return (toTime_ - startTime) * rewardPerSecond;
            return (toTime_ - fromTime_) * rewardPerSecond;
        }
    }

    /**
     * @notice View function to see pending rewardToken on frontend
     * @param pid_ The id of the pool
     * @param user_ Address of the user
     */
    function pendingReward(uint256 pid_, address user_) public view virtual override returns (uint256) {
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][user_];
        uint256 accRewardTokenPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = pool.totalBoostedShare;

        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 generatedReward_ = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 rewardTokenReward_ = (generatedReward_ * pool.allocPoint) / totalAllocPoint;
            accRewardTokenPerShare += (rewardTokenReward_ * REWARD_PRECISION) / tokenSupply;
        }

        // the boostedAmount is multiplied by 1 if there is no boost
        uint256 boostedAmount = (user.amount * getBoostMultiplier(user_, pid_)) / BOOST_PRECISION;
        return ((boostedAmount * accRewardTokenPerShare) / REWARD_PRECISION) - user.rewardDebt;
    }

    /**
     * @notice View function to see all pending rewardToken on frontend
     * @param user_ Address of the user
     */
    function pendingAllRewards(address user_) external view virtual override returns (uint256 total_) {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; pid++) {
            total_ += pendingReward(pid, user_);
        }
        return total_;
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; pid++) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param pid_ The id of the pool
     */
    function updatePool(uint256 pid_) public virtual returns (PoolInfo memory pool) {
        pool = poolInfo[pid_];
        if (block.timestamp <= pool.lastRewardTime) return pool;
        uint256 tokenSupply = pool.totalBoostedShare;
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            poolInfo[pid_] = pool;
            return pool;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint += pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            uint256 generatedReward_ = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 rewardTokenReward_ = (generatedReward_ * pool.allocPoint) / totalAllocPoint;
            pool.accRewardPerShare += (rewardTokenReward_ * REWARD_PRECISION) / tokenSupply;
        }
        pool.lastRewardTime = block.timestamp;
        poolInfo[pid_] = pool;
    }

    /**
     * @notice Deposit tokens.
     * @param pid_ The id of the pool
     * @param amount_ Amount of tokens to deposit
     */
    function deposit(uint256 pid_, uint256 amount_) external virtual override nonReentrant {
        PoolInfo memory pool = updatePool(pid_);
        UserInfo storage user = userInfo[pid_][msg.sender];
        uint256 multiplier = getBoostMultiplier(msg.sender, pid_);
        if (user.amount > 0) {
            _harvestReward(msg.sender, pid_, multiplier);
        }
        if (amount_ > 0) {
            uint256 beforeAmount = pool.token.balanceOf(address(this));
            pool.token.safeTransferFrom(msg.sender, address(this), amount_);
            uint256 afterAmount = pool.token.balanceOf(address(this));
            amount_ = afterAmount - beforeAmount; // fixes deflationary tokens

            if(pool.depositFee > 0) {
                uint256 depositFee = (amount_ * _getDepositFee(amount_, pool.depositFee, pid_)) / 10000;
                if(depositFee > 0) {
                    pool.token.safeTransfer(feeAddress, depositFee);
                }
                user.amount += amount_ - depositFee;
            } else {
                user.amount += amount_;
            }
            user.lastDepositTime = block.timestamp;

            pool.totalBoostedShare += (amount_ * multiplier) / BOOST_PRECISION;
        }

        user.rewardDebt = (((user.amount * multiplier) / BOOST_PRECISION) * pool.accRewardPerShare) / REWARD_PRECISION;
        poolInfo[pid_] = pool;

        emit Deposit(msg.sender, pid_, amount_);
    }

    /**
     * @notice Gets deposit fee. Override to add logic to reduce deposit fee
     * @param fee_ The pool's deposit fee
     */
    function _getDepositFee(uint256, uint256 fee_, uint256) internal virtual returns (uint256) {
        return fee_;
    }

    /**
     * @notice Withdraw tokens from pool
     * @param pid_ The id of the pool
     * @param amount_ Amount of tokens to withdraw
     */
    function withdraw(uint256 pid_, uint256 amount_) external virtual override nonReentrant {
        _withdraw(pid_, amount_);
    }

    /**
     * @notice Withdraw all tokens from pool
     * @param pid_ The id of the pool
     */
    function withdrawAll(uint256 pid_) external virtual override nonReentrant {
        _withdraw(pid_, userInfo[pid_][msg.sender].amount);
    }

    function _withdraw(uint256 pid_, uint256 amount_) internal virtual {
        PoolInfo memory pool = updatePool(pid_);
        UserInfo storage user = userInfo[pid_][msg.sender];
        if(user.amount < amount_) revert TooHigh();
        uint256 multiplier = getBoostMultiplier(msg.sender, pid_);
        if(user.amount > 0) {
            _harvestReward(msg.sender, pid_, multiplier);
        }
        if (amount_ > 0) {
            user.amount -= amount_;
            pool.token.safeTransfer(msg.sender, amount_);
            if(block.timestamp < getUserUnlockTime(msg.sender, pid_)) revert Locked();
        }
        user.rewardDebt = (((user.amount * multiplier) / BOOST_PRECISION) * pool.accRewardPerShare) / REWARD_PRECISION;
        poolInfo[pid_].totalBoostedShare -= (amount_ * multiplier) / BOOST_PRECISION;
        emit Withdraw(msg.sender, pid_, amount_);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param pid_ The id of the pool
     */
    function emergencyWithdraw(uint256 pid_) external virtual override nonReentrant {
        PoolInfo storage pool = poolInfo[pid_];
        UserInfo storage user = userInfo[pid_][msg.sender];
        if(block.timestamp < getUserUnlockTime(msg.sender, pid_)) revert Locked();
        uint256 amount_ = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 boostedAmount = (amount_ * getBoostMultiplier(msg.sender, pid_)) / BOOST_PRECISION;
        pool.totalBoostedShare = pool.totalBoostedShare > boostedAmount ? pool.totalBoostedShare - boostedAmount : 0;

        pool.token.safeTransfer(msg.sender, amount_);
        emit EmergencyWithdraw(msg.sender, pid_, amount_);
    }

    /**
     * @notice Harvest all rewards without withdrawing
     */
    function harvestAllRewards() external virtual override nonReentrant {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; pid++) {
            if (userInfo[pid][msg.sender].amount > 0) {
                _withdraw(pid, 0);
            }
        }
    }

    /**
     * @notice Harvest reward and send to user
     * @param user_ Address of user
     * @param pid_ The pool id
     * @param boostMultiplier_ The boost multiplier
     */
    function _harvestReward(address user_, uint256 pid_, uint256 boostMultiplier_) internal virtual {
        PoolInfo memory pool = poolInfo[pid_];
        UserInfo memory user = userInfo[pid_][user_];
        uint256 boostedAmount = (user.amount * boostMultiplier_) / BOOST_PRECISION;
        uint256 accReward = (boostedAmount * pool.accRewardPerShare) / REWARD_PRECISION;
        uint256 pending_ = accReward - user.rewardDebt;
        if (pending_ > 0) {
            _safeTokenTransfer(reward, user_, pending_);
            emit RewardPaid(user_, pending_);
        }
    }

    /**
     * @notice Get user unlock time for a specific pool id
     * @param user_ The user address
     * @param pid_ The pool id
     */
    function getUserUnlockTime(address user_, uint256 pid_) public view virtual override returns (uint256 unlockTime) {
        return userInfo[pid_][user_].lastDepositTime + poolInfo[pid_].lockTime;
    }

    /**
     * @notice Get user boost multiplier for specific pool id
     * @param user_ The user address
     * @param pid_ The pool id
     */
    function getBoostMultiplier(address user_, uint256 pid_) public view returns (uint256) {
        uint256 multiplier = userInfo[pid_][user_].boostMultiplier;
        return multiplier > BOOST_PRECISION ? multiplier : BOOST_PRECISION;
    }

    /**
     * @notice Update user boost factor.
     * @param user_ The user address for boost factor updates.
     * @param pid_ The pool id for the boost factor updates.
     * @param newMultiplier_ New boost multiplier
     */
    function updateBoostMultiplier(address user_, uint256 pid_, uint256 newMultiplier_) external virtual onlyBoostOperator nonReentrant {
        if(user_ == address(0)) revert ZeroAddress();
        if(newMultiplier_ < BOOST_PRECISION) revert TooLow();
        PoolInfo memory pool = updatePool(pid_);
        UserInfo storage user = userInfo[pid_][user_];

        uint256 prevMultiplier = getBoostMultiplier(user_, pid_);
        _harvestReward(user_, pid_, prevMultiplier);

        user.rewardDebt = (((user.amount * newMultiplier_) / BOOST_PRECISION) * (pool.accRewardPerShare)) / REWARD_PRECISION;
        pool.totalBoostedShare -= ((user.amount * prevMultiplier) / BOOST_PRECISION);
        pool.totalBoostedShare += ((user.amount * newMultiplier_) / BOOST_PRECISION);
        poolInfo[pid_] = pool;
        userInfo[pid_][user_].boostMultiplier = newMultiplier_;

        emit UpdateBoostMultiplier(user_, pid_, prevMultiplier, newMultiplier_);
    }

    /**
     * @notice Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewardToken.
     */
    function _safeTokenTransfer(address token_, address to_, uint256 amount_) internal virtual returns (uint256) {
        IERC20 token = IERC20(token_);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > 0) {
            if (amount_ > tokenBalance) {
                token.safeTransfer(to_, tokenBalance);
                return tokenBalance;
            } else {
                token.safeTransfer(to_, amount_);
                return amount_;
            }
        }
        return 0;
    }

    /**
     * @notice Increase reward balance and increase the endTime while keeping the reward rate
     * @param amount_ Amount to deposit
     */
    function increaseRewardBalance(uint256 amount_) external virtual onlyOperator {
        IERC20(reward).transferFrom(msg.sender, address(this), amount_);
        totalRewards += amount_;
        emit IncreaseRewardBalance(amount_);
        updateRewardRate(rewardPerSecond);
    }

    /**
     * @notice Update reward rate which will change the endTime
     * @param newRate_ The new reward rate per second
     */
    function updateRewardRate(uint256 newRate_) public virtual override onlyOperator {
        if(newRate_ > MAX_REWARD_PER_SECOND) revert TooHigh();
        uint256 oldRate_ = rewardPerSecond;
        massUpdatePools();
        if (block.timestamp > lastTimeUpdateRewardRate) {
            accumulatedRewardPaid += (block.timestamp - lastTimeUpdateRewardRate) * oldRate_;
            lastTimeUpdateRewardRate = block.timestamp;
        }
        if (accumulatedRewardPaid >= totalRewards) {
            endTime = block.timestamp;
            rewardPerSecond = 0;
        } else {
            rewardPerSecond = newRate_;
            uint256 secondLeft_ = (totalRewards - accumulatedRewardPaid) / newRate_;
            if(block.timestamp > startTime) {
                endTime = block.timestamp + secondLeft_;
            } else {
                endTime = startTime + secondLeft_;
            }
        }
        emit UpdateRewardRate(rewardPerSecond, endTime);
    }

    function setFeeAddress(address feeAddress_) external virtual onlyOperator {
        feeAddress = feeAddress_;
    }

    function governanceRecoverUnsupported(address token_, uint256 amount_, address to_) external virtual onlyOperator {
        if (block.timestamp < endTime + 60 days) {
            // do not allow to drain core token (rewardToken or lps) if less than 60 days after pool ends
            if(token_ == reward) revert Token();
            uint256 length = poolInfo.length;
            for (uint256 pid; pid < length; pid++) {
                PoolInfo storage pool = poolInfo[pid];
                if(token_ == address(pool.token)) revert Token();
            }
        }
        IERC20(token_).safeTransfer(to_, amount_);
    }
}

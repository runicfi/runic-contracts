// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IBoardroomFee.sol";
import "./interfaces/IClaim.sol";
import "./interfaces/ITreasury.sol";

/**
 * @title Boardroom
 */
contract BoardroomUpgradeable is ContractGuard, AccessControlEnumerableUpgradeable, UUPSUpgradeable, IBoardroom, IBoardroomFee {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Boardseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct Snapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    uint256 public constant REWARD_PRECISION = 1e18;
    uint256 private _totalShare;
    mapping(address => uint256) private _balances;
    bool public started;
    IERC20Upgradeable public rewardToken;
    IERC20Upgradeable public share;
    ITreasury public treasury;
    mapping(address => Boardseat) public seats;  // user => seat (share)
    Snapshot[] public history;                   // board history
    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;
    // fees
    address public feeAddress;
    uint256 public withdrawFee;
    uint256 public stakeFee;
    uint256 public constant MAX_WITHDRAW_FEE = 2000; // 20%
    uint256 public constant MAX_STAKE_FEE = 2000; // 20%
    EnumerableSetUpgradeable.AddressSet _claimHooks; // called on when user claim to update any stats related to the account

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);
    event RewardBurned(address indexed user, uint256 reward);
    event ErrorString(string reason);
    event ErrorPanic(uint reason);
    event ErrorBytes(bytes reason);

    error AlreadyStarted();             // 0x1fbde445
    error BoardroomTotalShareZero();    // 0xdc694eba
    error CannotBeZero();               // 0x1e1d0ab5
    error DoesNotExist();               // 0xb0ce7591
    error Exist();                      // 0x65956805
    error FeeTooHigh();                 // 0xcd4e6167
    error NotOperator();                // 0x7c214f04
    error NoSeat();                     // 0x9a39f3a6
    error OutOfRange();                 // 0x7db3aba7
    error RewardLockup();               // 0xbc99f144
    error Token();                      // 0xc2412676
    error WithdrawGreaterThanStaked();  // 0x81b72a7b
    error WithdrawLockup();             // 0x9c8cd822
    error ZeroAddress();                // 0xd92e233d

    modifier onlyOperator {
        if(!AccessControlUpgradeable.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    modifier seatExists {
        if(balanceOf(msg.sender) == 0) revert NoSeat();
        _;
    }

    modifier updateReward(address member_) {
        if(member_ != address(0)) {
            Boardseat memory seat = seats[member_];
            seat.rewardEarned = earned(member_);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            seats[member_] = seat;
        }
        _;
    }

    modifier notStarted {
        if(started) revert AlreadyStarted();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Boardroom_init();
    }

    function __Boardroom_init() internal onlyInitializing {
        __Boardroom_init_unchained();
    }

    function __Boardroom_init_unchained() internal onlyInitializing {
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IBoardroom).interfaceId ||
        interfaceId == type(IBoardroomFee).interfaceId;
    }

    function totalShare() public view override returns (uint256) {
        return _totalShare;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function start(IERC20Upgradeable rewardToken_, IERC20Upgradeable share_, ITreasury treasury_) external notStarted onlyOperator {
        rewardToken = rewardToken_;
        share = share_;
        treasury = treasury_;
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, address(treasury_));
        Snapshot memory genesisSnapshot = Snapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        history.push(genesisSnapshot);
        withdrawLockupEpochs = 4; // Lock for 4 epochs (24h) before release withdraw. Changed from 6 epochs
        rewardLockupEpochs = 2; // Lock for 2 epochs (12h) before release claimReward. Changed from 3 epochs
        started = true;
        emit Initialized(msg.sender, block.number);
    }

    function setLockUp(uint256 withdrawLockupEpochs_, uint256 rewardLockupEpochs_) external onlyOperator {
       if(withdrawLockupEpochs_ < rewardLockupEpochs_ || withdrawLockupEpochs_ > 56) revert OutOfRange(); // <= 2 week
        withdrawLockupEpochs = withdrawLockupEpochs_;
        rewardLockupEpochs = rewardLockupEpochs_;
    }

    function setFeeAddress(address feeAddress_) external onlyOperator {
        if(feeAddress_ == address(0)) revert ZeroAddress();
        feeAddress = feeAddress_;
    }

    function setStakeFee(uint256 stakeFee_) external override onlyOperator {
        if(stakeFee_ > MAX_STAKE_FEE) revert FeeTooHigh();
        stakeFee = stakeFee_;
    }

    function setWithdrawFee(uint256 withdrawFee_) external override onlyOperator {
        if(withdrawFee_ > MAX_WITHDRAW_FEE) revert FeeTooHigh();
        withdrawFee = withdrawFee_;
    }

    function latestSnapshotIndex() public view returns (uint256) {
        return history.length - 1;
    }

    function getLatestSnapshot() internal view returns (Snapshot memory) {
        return history[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address seat) public view returns (uint256) {
        return seats[seat].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address seat) internal view returns (Snapshot memory) {
        return history[getLastSnapshotIndexOf(seat)];
    }

    function canWithdraw(address seat) external view returns (bool) {
        return seats[seat].epochTimerStart + withdrawLockupEpochs <= treasury.epoch();
    }

    function canClaimReward(address seat) external view returns (bool) {
        return seats[seat].epochTimerStart + rewardLockupEpochs <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getPegTokenPrice() external view returns (uint256) {
        return treasury.getPegTokenPrice();
    }

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address seat) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(seat).rewardPerShare;
        return ((balanceOf(seat) * (latestRPS - storedRPS)) / REWARD_PRECISION) + seats[seat].rewardEarned;
    }

    function stake(uint256 amount) public onlyOneBlock updateReward(msg.sender) {
        if(amount == 0) revert CannotBeZero();
        share.safeTransferFrom(msg.sender, address(this), amount);
        if(stakeFee > 0) {
            uint256 feeAmount = (amount * stakeFee) / 10000;
            share.safeTransfer(feeAddress, feeAmount);
            amount -= feeAmount;
        }
        _totalShare += amount;
        _balances[msg.sender] += amount;
        seats[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Reward is burned if the user withdraws any amount
     */
    function withdraw(uint256 amount) public onlyOneBlock seatExists updateReward(msg.sender) {
        if(amount == 0) revert CannotBeZero();
        if(seats[msg.sender].epochTimerStart + withdrawLockupEpochs > treasury.epoch()) revert WithdrawLockup();
        _burnReward();
        if(_balances[msg.sender] < amount) revert WithdrawGreaterThanStaked();
        _totalShare -= amount;
        _balances[msg.sender] -= amount;
        if(withdrawFee > 0) {
            uint256 feeAmount = (amount * withdrawFee) / 10000;
            share.safeTransfer(feeAddress, feeAmount);
            amount -= feeAmount;
        }
        share.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function claimReward() public onlyOneBlock updateReward(msg.sender) {
        _claimReward();
    }

    function _claimReward() internal {
        uint256 reward = seats[msg.sender].rewardEarned;
        if(reward > 0) {
            if(seats[msg.sender].epochTimerStart + rewardLockupEpochs > treasury.epoch()) revert RewardLockup();
            seats[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            seats[msg.sender].rewardEarned = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            for(uint256 i; i < _claimHooks.length(); i++) {
                try IClaim(_claimHooks.at(i)).claim(msg.sender, reward) {
                } catch Error(string memory reason) {
                    emit ErrorString(reason);
                } catch Panic(uint reason) {
                    emit ErrorPanic(reason);
                } catch (bytes memory reason) {
                    emit ErrorBytes(reason);
                }
            }
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _burnReward() internal {
        uint256 reward = seats[msg.sender].rewardEarned;
        if(reward > 0) {
            seats[msg.sender].rewardEarned = 0;
            IERC20Burnable(address(rewardToken)).burn(reward);
            emit RewardBurned(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount) external override onlyOneBlock onlyOperator {
        if(amount == 0) revert CannotBeZero();
        if(totalShare() == 0) revert BoardroomTotalShareZero();

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS + ((amount * REWARD_PRECISION) / totalShare());

        Snapshot memory newSnapshot = Snapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
        });
        history.push(newSnapshot);

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function setTreasury(ITreasury treasury_) external onlyOperator {
        AccessControlUpgradeable._revokeRole(AccessControlConstants.OPERATOR_ROLE, address(treasury));
        treasury = treasury_;
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, address(treasury_));
    }

    function addClaimHook(address contract_) external onlyOperator {
        if(_claimHooks.contains(contract_)) revert Exist();
        _claimHooks.add(contract_);
    }

    function removeClaimHook(address contract_) external onlyOperator {
        if(!_claimHooks.contains(contract_)) revert DoesNotExist();
        _claimHooks.remove(contract_);
    }

    function governanceRecoverUnsupported(address token_, uint256 amount_, address to_) external onlyOperator {
        // do not allow to drain core tokens
        if(token_ == address(rewardToken)) revert Token();
        if(token_ == address(share)) revert Token();
        IERC20Upgradeable(token_).safeTransfer(to_, amount_);
    }
}
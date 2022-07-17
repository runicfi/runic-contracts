// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardPool.sol";

/**
 * @title GenesisRewardPool
 */
contract GenesisRewardPool is RewardPool {
    uint256[] public epochTotalRewards = [
        97500 ether,
        82500 ether,
        67500 ether,
        52500 ether
    ];
    uint256[4] public epochEndTimes; // Time when each epoch ends.
    uint256[5] public epochRewardPerSecond; // Reward per second for each of 4 weeks (last item is equal to 0 - for sanity).
    mapping(uint256 => mapping(address => bool)) public whitelistUsers; // whitelist users from deposit fees

    error NotSupported(); // 0xa0387940

    constructor(address rewardToken_, address feeAddress_, uint256 startTime_) RewardPool(rewardToken_, feeAddress_, startTime_) {
        epochEndTimes[0] = startTime_ + 7 days; // 1st week
        epochEndTimes[1] = epochEndTimes[0] + 7 days; // 2nd week
        epochEndTimes[2] = epochEndTimes[1] + 7 days; // 3rd week
        epochEndTimes[3] = epochEndTimes[2] + 7 days; // 4th week

        epochRewardPerSecond[0] = epochTotalRewards[0] / 7 days;
        epochRewardPerSecond[1] = epochTotalRewards[1] / 7 days;
        epochRewardPerSecond[2] = epochTotalRewards[2] / 7 days;
        epochRewardPerSecond[3] = epochTotalRewards[3] / 7 days;
        epochRewardPerSecond[4] = 0;

        endTime = startTime_ + 28 days;
        totalRewards = 300_000 ether;
    }

    /**
     * @notice Allows for change after deployment of contract but before startTime.
     * This function should be override to adjust for endTime if any
     * @param startTime_ cannot be changed once startTime is met
     */
    function setStartTime(uint256 startTime_) external virtual override onlyOperator {
        if(block.timestamp > startTime || block.timestamp > startTime_) revert Late();
        startTime = startTime_;
        epochEndTimes[0] = startTime_ + 7 days; // 1st week
        epochEndTimes[1] = epochEndTimes[0] + 7 days; // 2nd week
        epochEndTimes[2] = epochEndTimes[1] + 7 days; // 3rd week
        epochEndTimes[3] = epochEndTimes[2] + 7 days; // 4th week
        endTime = startTime_ + 28 days;
        lastTimeUpdateRewardRate = startTime_;
        // go through each existing pool and update lastRewardTime if it is less
        uint256 length = poolInfo.length;
        for(uint256 pid; pid < length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            if(pool.lastRewardTime < startTime_) pool.lastRewardTime = startTime_;
        }
    }

    function getRewardPerSecond() external view override returns (uint256) {
        for (uint8 epochId = 0; epochId <= 3; epochId++) {
            if (block.timestamp <= epochEndTimes[epochId])
                return epochRewardPerSecond[epochId];
        }
        return 0;
    }

    /**
     * @notice Return accumulate rewards over the given fromTime_ to toTime_
     * Override this if there is no endTime
     */
    function getGeneratedReward(uint256 fromTime_, uint256 toTime_) public view override returns (uint256) {
        for (uint8 epochId = 4; epochId >= 1; epochId--) {
            if (toTime_ >= epochEndTimes[epochId - 1]) {
                if (fromTime_ >= epochEndTimes[epochId - 1]) {
                    return (toTime_ - fromTime_) * epochRewardPerSecond[epochId];
                }
                uint256 generatedReward_ = (toTime_ - epochEndTimes[epochId - 1]) * epochRewardPerSecond[epochId];
                if (epochId == 1) {
                    return generatedReward_ + ((epochEndTimes[0] - fromTime_) * epochRewardPerSecond[0]);
                }
                for (epochId = epochId - 1; epochId >= 1; epochId--) {
                    if (fromTime_ >= epochEndTimes[epochId - 1]) {
                        return generatedReward_ + ((epochEndTimes[epochId] - fromTime_) * epochRewardPerSecond[epochId]);
                    }
                    generatedReward_ = generatedReward_ + ((epochEndTimes[epochId] - epochEndTimes[epochId - 1]) * epochRewardPerSecond[epochId]);
                }
                return generatedReward_ + ((epochEndTimes[0] - fromTime_) * epochRewardPerSecond[0]);
            }
        }
        return (toTime_ - fromTime_) * epochRewardPerSecond[0];
    }

    /**
     * @notice Gets deposit fee. Override to add logic to reduce deposit fee
     * @param fee_ The pool's deposit fee
     * @param pid_ The pool id
     */
    function _getDepositFee(uint256, uint256 fee_, uint256 pid_) internal virtual override returns (uint256) {
        if(whitelistUsers[pid_][msg.sender]) return 0;
        return fee_;
    }

    function addWhitelistUsers(uint256 pid_, address[] calldata users_) external onlyOperator {
        for(uint256 i; i < users_.length; i++) {
            whitelistUsers[pid_][users_[i]] = true;
        }
    }

    function removeWhitelistUsers(uint256 pid_, address[] calldata users_) external onlyOperator {
        for(uint256 i; i < users_.length; i++) {
            whitelistUsers[pid_][users_[i]] = false;
        }
    }

    /**
     * @notice Get user unlock time for a specific pool id
     * Genesis pool will not have lock time
     */
    function getUserUnlockTime(address, uint256) public pure override returns (uint256) {
        return 0;
    }

    function updateBoostMultiplier(address, uint256, uint256) external pure override {
        revert NotSupported();
    }

    function increaseRewardBalance(uint256) external pure override {
        revert NotSupported();
    }

    function updateRewardRate(uint256) public pure override {
        revert NotSupported();
    }
}
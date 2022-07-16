// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardPool {
    function reward() external view returns (address);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function withdrawAll(uint256 pid) external;
    function harvestAllRewards() external;
    function emergencyWithdraw(uint256 pid) external;
    function pendingReward(uint256 pid, address user) external view returns (uint256);
    function pendingAllRewards(address user) external view returns (uint256);
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt, uint256 boostMultiplier, uint256 lastDepositTime);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function getPoolInfo(uint256 pid) external view returns (address token, uint256 allocPoint);
    function getRewardPerSecond() external view returns (uint256);
    function getUserUnlockTime(address user, uint256 pid) external view returns (uint256 unlockTime);
    function updateRewardRate(uint256 newRate) external;
}
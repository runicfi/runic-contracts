// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardNFTPool {
    function reward() external view returns (address);
    function deposit(uint256 pid, uint256[] calldata tokenIds) external payable;
    function withdraw(uint256 pid, uint256[] memory tokenIds) external;
    function withdrawAll(uint256 pid) external;
    function harvestAllRewards() external;
    function emergencyWithdraw(uint256 pid_) external;
    function pendingReward(uint256 pid, address user) external view returns (uint256);
    function pendingAllRewards(address user) external view returns (uint256);
    function getUserInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt, uint256 boostMultiplier, uint256 lastDepositTime, uint256[] memory tokenIds);
    function getNFTInfo(uint256 pid, uint256 tokenId) external view returns (uint256 lastDepositTime);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function getPoolInfo(uint256 pid) external view returns (address token, uint256 allocPoint);
    function getUserUnlockTime(address user, uint256 pid) external view returns (uint256 unlockTime);
    function getNFTUnlockTime(uint256 tokenId, uint256 pid) external view returns (uint256 unlockTime);
    function getRewardPerSecond() external view returns (uint256);
    function updateRewardRate(uint256 newRate) external;
}
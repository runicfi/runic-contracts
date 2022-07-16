// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTBoostRewardPool {
    function getNFTContracts() external view returns (address[] memory nftContracts);
    function getNFTBoostContract(address nftContract) external view returns (address nftBoostContract);
    function getUserNFTs(address user, uint256 pid, address nftContract) external view returns (uint256[] memory tokenIds);
    function getNFTBoost(address user, uint256 pid) external view returns (uint256 boost);
    function depositNFT(uint256 pid, address nftContract, uint256[] calldata tokenIds) external;
    function withdrawNFT(uint256 pid, address nftContract, uint256[] calldata tokenIds) external;
}
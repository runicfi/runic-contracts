// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTWithdraw {
    // withdrawTime is not needed since contract can check block.timestamp
    function withdrawNFT(address account, address nftContract, uint256[] memory tokenIds, uint256[] memory stakeTime, uint256 pid) external;
}
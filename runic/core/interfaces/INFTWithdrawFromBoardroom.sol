// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTWithdrawFromBoardroom {
    // withdrawTime is not needed since contract can check block.timestamp
    function withdrawNFTFromBoardroom(address account, address nftContract, uint256[] memory tokenIds, uint256[] memory stakeTime) external;
}
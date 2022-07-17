// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/BlocksNFTLib.sol";

interface IBlocksNFT {
    function setBlockAttributes(uint256, BlocksNFTLib.BlockAttributes memory) external;
    function getBlockAttributes(uint256) external view returns (BlocksNFTLib.BlockAttributes memory);
}

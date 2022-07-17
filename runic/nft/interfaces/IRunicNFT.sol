// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/RunicNFTLib.sol";

interface IRunicNFT {
    function setRunicAttributes(uint256, RunicNFTLib.RunicAttributes memory) external;
    function getRunicAttributes(uint256) external view returns (RunicNFTLib.RunicAttributes memory);
}
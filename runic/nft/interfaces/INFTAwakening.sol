// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTAwakening {
    function getAwakening(uint256 tokenId) external view returns (uint32 awakening);
    function setAwakening(uint256 tokenId, uint32 awakening) external;
}
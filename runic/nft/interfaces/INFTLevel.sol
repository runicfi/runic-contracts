// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTLevel {
    function getLevel(uint256 tokenId) external view returns (uint32 level);
    function setLevel(uint256 tokenId, uint32 level) external;
}
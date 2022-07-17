// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTRarity {
    function getRarity(uint256 tokenId) external view returns (uint32 rarity);
}
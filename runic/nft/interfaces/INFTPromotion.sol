// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPromotion {
    function getPromotion(uint256 tokenId) external view returns (uint32 promotion);
    function setPromotion(uint256 tokenId, uint32 promotion) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITreasury {
    function epoch() external view returns (uint256);
    function nextEpochPoint() external view returns (uint256);
    function getPegTokenPrice() external view returns (uint256);
    function getPegTokenPriceUpdated() external view returns (uint256);
    function getPegTokenCirculatingSupply() external view returns (uint256);
    function getPegTokenExcludedSupply() external view returns (uint256);
    function getPegTokenExpansionRate() external view returns (uint256);
    function getPegTokenExpansionAmount() external view returns (uint256);
    function previousEpochPegTokenPrice() external view returns (uint256);
    function getBondDiscountRate() external view returns (uint256);
    function getBondPremiumRate() external view returns (uint256);
    function buyBonds(uint256 amount, uint256 targetPrice) external;
    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITaxableToken {
    function isAddressFromTaxExcluded(address address_) external returns (bool);
    function isAddressToTaxExcluded(address address_) external returns (bool);
    function taxRate() external view returns (uint256 rate);
    function priceFloor() external view returns (uint256 priceFloor);
    function priceCeiling() external view returns (uint256 priceCeiling);
    function getTaxRate() external view returns (uint256 rate);
    function setTaxCollectorAddress(address taxCollectorAddress) external;
    function setTaxTiersTwap(uint8 index, uint256 value) external;
    function setTaxTiersRate(uint8 index, uint256 value) external;
    function setAutoCalculateTax(bool enabled) external;
    function setTaxRate(uint256 taxRate) external;
    function setBurnThreshold(uint256 burnThreshold) external;
    function setPriceFloor(uint256 priceFloor) external;
    function setPriceCeiling(uint256 priceCeiling) external;
    function setSellCeilingSupplyRate(uint256 sellCeilingSupplyRate_) external;
    function setSellCeilingLiquidityRate(uint256 sellCeilingLiquidityRate_) external;
    function sellingLimit() external view returns (uint256);
    function setExcludeFromTaxAddress(address address_, bool exclude) external;
    function setExcludeToTaxAddress(address address_, bool exclude) external;
    function setWhitelistAddress(address account, bool whitelist) external;
}
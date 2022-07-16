// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTToken {
    function isAddressFromNFTExcluded(address address_) external view returns (bool);
    function isAddressToNFTExcluded(address address_) external view returns (bool);
    function nftPowerRequired() external view returns (uint256 power);
    function getNFTPowerRequired() external view returns (uint256 power);
    function setNFTTiersTwap(uint8 index, uint256 value) external;
    function setNFTTiersPowerRequired(uint8 index, uint256 value) external;
    function setAutoCalculateNFTPowerRequired(bool enabled) external;
    function setNFTPowerRequired(uint256 amount) external;
    function setExcludeFromNFTAddress(address address_, bool exclude) external;
    function setExcludeToNFTAddress(address address_, bool exclude) external;
    function addNFTContract(address contract_) external;
    function removeNFTContract(address contract_) external;
    function getNFTContracts() external view returns (address[] memory contracts_);
    function addNFTPoolsContract(address contract_) external;
    function removeNFTPoolsContract(address contract_) external;
    function getNFTPoolsContracts() external view returns (address[] memory contracts_);
}
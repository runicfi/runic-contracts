// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPower {
    function getPower(uint256 tokenId) external view returns (uint256 power);
    function getUserPower(address account) external view returns (uint256 power);
    function getTotalPower() external view returns (uint256 power);
    function addPower(address account, uint256 tokenId, uint256 power) external;
    function removePower(address account, uint256 tokenId, uint256 power) external;
}
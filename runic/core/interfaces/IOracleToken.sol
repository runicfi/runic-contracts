// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracleToken {
    function oracle() external view returns (address oracle);
    function setOracle(address oracle) external;
    function getPrice() external view returns (uint256 price);
    function getPriceUpdated() external view returns (uint256 price);
}
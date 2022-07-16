// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {
    function claim(uint256 amount_) external;
    function setClaimPrice(uint256 price_) external;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaim {
    function claim(address account, uint256 amount) external;
}
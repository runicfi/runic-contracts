// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256) external;
    function burnFrom(address, uint256) external;
}

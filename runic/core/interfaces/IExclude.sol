// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExclude {
    function setExcludeAddress(address account, bool exclude) external;
}
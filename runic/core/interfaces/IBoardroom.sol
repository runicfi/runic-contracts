// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoardroom {
    function allocateSeigniorage(uint256 amount) external;
    function totalShare() external returns (uint256 supply);
}

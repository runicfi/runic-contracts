// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function update() external;
    function consult(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function twap(address token, uint256 amountIn) external view returns (uint144 amountOut);
    function getPegPrice() external view returns (uint256 amountOut);
    function getPegPriceUpdated() external view returns (uint256 amountOut);
}
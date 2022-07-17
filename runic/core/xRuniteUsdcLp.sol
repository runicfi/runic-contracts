// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./xLiquidityToken.sol";

/**
 * @title xRuniteUsdcLp
 * Locked liquidity token
 */
contract xRuniteUsdcLp is xLiquidityToken {
    constructor(address liquidityOperator_) xLiquidityToken("xRuniteUsdcLp", "xRuniteUsdc-LP", liquidityOperator_) {}
}
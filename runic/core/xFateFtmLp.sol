// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./xLiquidityToken.sol";

/**
 * @title xFateFtmLp
 * Locked liquidity token
 */
contract xFateFtmLp is xLiquidityToken {
    constructor(address liquidityOperator_) xLiquidityToken("xFateFtmLp", "xFateFTM-LP", liquidityOperator_) {}
}
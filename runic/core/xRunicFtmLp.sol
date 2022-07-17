// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./xLiquidityToken.sol";

/**
 * @title xRunicFtmLp
 * Locked liquidity token
 */
contract xRunicFtmLp is xLiquidityToken {
    constructor(address liquidityOperator_) xLiquidityToken("xRunicFtmLp", "xRunicFTM-LP", liquidityOperator_) {}
}
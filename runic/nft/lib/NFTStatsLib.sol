// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library NFTStatsLib {
    struct Stats {
        uint32 level;
        uint32 rarity;
        uint32 promotion;
        uint32 awakening;
        uint256 power;
    }
}
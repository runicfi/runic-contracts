// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/NFTStatsLib.sol";
import "./INFTAwakening.sol";
import "./INFTLevel.sol";
import "./INFTPower.sol";
import "./INFTPromotion.sol";
import "./INFTRarity.sol";

interface INFTStats is INFTAwakening, INFTLevel, INFTPower, INFTPromotion, INFTRarity {
    function getStats(uint256 tokenId) external view returns (NFTStatsLib.Stats memory stats);
}
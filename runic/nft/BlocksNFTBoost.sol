// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../lib/AccessControlConstants.sol";
import "./interfaces/INFTBoost.sol";
import "./interfaces/INFTStats.sol";

/**
 * @title BlocksNFTBoost
 * calculates the boost from NFT based off stats
 */
contract BlocksNFTBoost is AccessControlEnumerable, INFTBoost {
    address public nftContract;
    uint256 public constant BOOST_PRECISION = 1e10;
    uint32 private constant RARITY_COMMON = 0;
    uint32 private constant RARITY_RARE = 1;
    uint32 private constant RARITY_EPIC = 2;
    uint32 private constant RARITY_LEGENDARY = 3;
    uint32 private constant RARITY_MYTHIC = 4;
    uint32 private constant RARITY_SPECIAL = 10;
    uint256 private constant RARITY_COMMON_BOOST = 0.01e10; // 1%
    uint256 private constant RARITY_RARE_BOOST = 0.025e10; // 2.5%
    uint256 private constant RARITY_EPIC_BOOST = 0.05e10; // 5%
    uint256 private constant RARITY_LEGENDARY_BOOST = 0.1e10; // 10%
    uint256 private constant RARITY_MYTHIC_BOOST = 0.20e10; // 20%
    uint256 private constant RARITY_SPECIAL_BOOST = 0.12e10; // 12%
    uint256 private constant MAX_POWER_BOOST = 0.05e10; // 5%
    uint256 private constant BOOST_PER_LEVEL = 0.0005e10; // 0.05%
    uint256 private constant BOOST_PER_POWER = 0.00001e10; // 0.001%
    uint256 private constant BOOST_PER_PROMOTION = 0.0025e10; // 0.25%
    uint256 private constant BOOST_PER_AWAKENING = 0.0025e10; // 0.25%

    constructor(address nftContract_) {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        nftContract = nftContract_;
    }

    /**
     * getBoost based off rarity and power
     * max boost: 25% excluding mythic
     * boost:
     * - common: 1%, rare: 2.5%, epic: 5%, legendary: 10%, special: 12%
     * - level: 0.05% for each level with level cap of 100 (5%)
     * - power: 0.001% for each power with cap of 5%
     * - promotion: 0.25% for each promotion with a cap of 2.5%
     * - awakening: 0.25% for each awakening with a cap of 2.5%
     * @return boost for each tokenId with BOOST_PRECISION
     */
    function getBoost(address, address, uint256, uint256[] calldata tokenIds_) external view override returns (uint256[] memory boost) {
        boost = new uint256[](tokenIds_.length);
        INFTStats nft = INFTStats(nftContract);
        for(uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            NFTStatsLib.Stats memory stats = nft.getStats(tokenId);
            boost[i] += stats.level * BOOST_PER_LEVEL;
            boost[i] += stats.promotion * BOOST_PER_PROMOTION;
            boost[i] += stats.awakening * BOOST_PER_AWAKENING;
            if((stats.power * BOOST_PER_POWER) < MAX_POWER_BOOST) {
                boost[i] += (stats.power * BOOST_PER_POWER);
            } else {
                boost[i] += MAX_POWER_BOOST;
            }
            if(stats.rarity == RARITY_COMMON) {
                boost[i] += RARITY_COMMON_BOOST;
            } else if(stats.rarity == RARITY_RARE) {
                boost[i] += RARITY_RARE_BOOST;
            } else if(stats.rarity == RARITY_EPIC) {
                boost[i] += RARITY_EPIC_BOOST;
            } else if(stats.rarity == RARITY_LEGENDARY) {
                boost[i] += RARITY_LEGENDARY_BOOST;
            } else if(stats.rarity == RARITY_MYTHIC) {
                boost[i] += RARITY_MYTHIC_BOOST;
            } else if(stats.rarity == RARITY_SPECIAL) {
                boost[i] += RARITY_SPECIAL_BOOST;
            }

        }
        return boost;
    }

    function setNFTContract(address nftContract_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        nftContract = nftContract_;
    }
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @notice Generic Runic NFT stats
 */
library RunicNFTLib {
    struct RunicAttributes {
        uint32 level;
        uint32 rarityId;
        uint32 backgroundId;
        uint32 bodyId;
        uint32 elementId;
        uint32 foregroundId;
        uint32 promotion;
        uint32 awakening;
    }
}
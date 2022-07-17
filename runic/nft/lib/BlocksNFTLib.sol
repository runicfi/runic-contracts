// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @notice Block NFT stats
 */
library BlocksNFTLib {
    struct BlockAttributes {
        uint32 categoryId; // stat, resource, unit, element, special
        uint32 typeId; // specific stat, resource, unit, element, special within the categoryId
        uint32 reserved;
        uint32 reserved2;
    }
}
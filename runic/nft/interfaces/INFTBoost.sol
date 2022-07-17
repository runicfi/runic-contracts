// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTBoost {
    /**
     * @notice Get the boost using input
     * @param source The calling contract such as the pool contract
     * @param user Address of the user
     * @param id The id of the pool or id of location
     * @param tokenIds The tokenIds
     * @return boost The boost for each tokenId without the precision. The calling contract will use the boost precision it has set
     */
    function getBoost(address source, address user, uint256 id, uint256[] calldata tokenIds) external view returns (uint256[] memory boost);
}
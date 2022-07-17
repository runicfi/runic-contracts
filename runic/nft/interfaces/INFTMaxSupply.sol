// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTMaxSupply {
    function maxSupply() external view returns (uint256 maxSupply);
}
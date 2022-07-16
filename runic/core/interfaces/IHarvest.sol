// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHarvest {
    /**
     * @notice hook to run another contract's logic on harvest
     * @param account Address of user
     * @param amount Amount of harvest
     * @param pid The pool id
     */
    function harvest(address account, uint256 amount, uint256 pid) external;
}
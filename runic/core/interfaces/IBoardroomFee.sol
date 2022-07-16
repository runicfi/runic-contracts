// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBoardroomFee {
    function setStakeFee(uint256 fee) external;
    function setWithdrawFee(uint256 fee) external;
}
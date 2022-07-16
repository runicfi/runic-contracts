// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IRegulationStats {
    function addEpochInfo(
        uint256 epochNumber,
        uint256 twap,
        uint256 expanded,
        uint256 boardroomFunding,
        uint256 daoFunding,
        uint256 devFunding
    ) external;

    function addBonded(uint256 epochNumber, uint256 added) external;

    function addRedeemed(uint256 epochNumber, uint256 added) external;
}
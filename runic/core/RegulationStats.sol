// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../lib/AccessControlConstants.sol";
import "./interfaces/IRegulationStats.sol";

/**
 * @title RegulationStats
 * Keeps track of epoch stats
 */
contract RegulationStats is AccessControlEnumerable, IRegulationStats {

    struct EpochStats {
        uint256 epoch;
        uint256 twap;
        uint256 expanded;
        uint256 boardroomFunding;
        uint256 daoFunding;
        uint256 devFunding;
        uint256 bonded;
        uint256 redeemed;
    }

    mapping(uint256 => EpochStats) public stats; // epoch => stats
    address public treasury;

    error NotOperator(); // 0x7c214f04

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    constructor(address treasury_) {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        treasury = treasury_;
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, treasury_);
    }

    function addEpochInfo(
        uint256 epochNumber,
        uint256 twap,
        uint256 expanded,
        uint256 boardroomFunding,
        uint256 daoFunding,
        uint256 devFunding
    ) external onlyOperator {
        EpochStats memory epochStats = EpochStats({
            epoch: epochNumber,
            twap: twap,
            expanded: expanded,
            boardroomFunding: boardroomFunding,
            daoFunding: daoFunding,
            devFunding: devFunding,
            bonded: 0,
            redeemed: 0
        });
        stats[epochNumber] = epochStats;
    }

    function addBonded(uint256 epochNumber, uint256 added) external onlyOperator {
        stats[epochNumber].bonded += added;
    }

    function addRedeemed(uint256 epochNumber, uint256 added) external onlyOperator {
        stats[epochNumber].redeemed += added;
    }

    function setTreasury(address treasury_) external onlyOperator {
        AccessControl._revokeRole(AccessControlConstants.OPERATOR_ROLE, treasury);
        treasury = treasury_;
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, treasury_);
    }

    function getRegulationStats(uint256 start_, uint256 end_) external view returns (EpochStats[] memory epochStats) {
        epochStats = new EpochStats[](end_ - start_);
        for(uint256 i = start_; i < end_; i++) {
            epochStats[i] = stats[i];
        }
        return epochStats;
    }
}
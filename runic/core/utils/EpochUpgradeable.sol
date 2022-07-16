// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../../../lib/AccessControlConstants.sol";

contract EpochUpgradeable is AccessControlEnumerableUpgradeable {
    uint256 private _period;
    uint256 private _startTime;
    uint256 private _lastEpochTime;
    uint256 private _epoch;

    error NotOperator(); // 0x7c214f04
    error NotStarted();  // 0x6f312cbd
    error OnlyOperatorAllowedForPreEpoch(); // 0x9aabbe2e
    error OutOfRange();  // 0x7db3aba7

    modifier onlyOperator {
        if(!AccessControlUpgradeable.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    modifier checkStartTime {
        if(block.timestamp < _startTime) revert NotStarted();
        _;
    }

    modifier checkEpoch {
        uint256 nextEpochPoint_ = nextEpochPoint();
        if(block.timestamp < nextEpochPoint_) {
            if(!AccessControlUpgradeable.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert OnlyOperatorAllowedForPreEpoch();
            _;
        } else {
            _;
            uint256 numEpoch = (block.timestamp - _lastEpochTime) / _period;
            _lastEpochTime += numEpoch * _period;
            _epoch += numEpoch;
        }
    }

    function __Epoch_init_unchained(uint256 period_, uint256 startTime_, uint256 startEpoch_) internal onlyInitializing {
        _period = period_;
        _startTime = startTime_;
        _epoch = startEpoch_;
        _lastEpochTime = startTime_ - period_;
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return _epoch;
    }

    function getPeriod() external view returns (uint256) {
        return _period;
    }

    function getStartTime() external view returns (uint256) {
        return _startTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return _lastEpochTime + _period;
    }

    function getLastEpochTime() external view returns (uint256) {
        return _lastEpochTime;
    }

    function setPeriod(uint256 period_) external onlyOperator {
        if(period_ < 1 hours || period_ > 48 hours) revert OutOfRange();
        _period = period_;
    }

    function setEpoch(uint256 epoch_) external onlyOperator {
        _epoch = epoch_;
    }

    function setLastEpochTime(uint256 lastEpochTime_) external onlyOperator {
        _lastEpochTime = lastEpochTime_;
    }

    uint256[46] private __gap;
}
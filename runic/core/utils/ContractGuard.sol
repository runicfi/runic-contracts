// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    error OneBlockOneFunction(); // 0x0e3b65cb

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        if(checkSameOriginReentranted() || checkSameSenderReentranted()) revert OneBlockOneFunction();
        _;
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

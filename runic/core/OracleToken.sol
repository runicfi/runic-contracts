// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../lib/AccessControlConstants.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IOracleToken.sol";

/**
 * @title OracleToken
 */
abstract contract OracleToken is AccessControlEnumerable, IOracleToken {
    address public override oracle;

    error FailedToGetPrice();
    error IndexTooLow();
    error IndexTooHigh();
    error NotOperator();
    error ZeroAddress();

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IOracleToken).interfaceId;
    }

    function setOracle(address oracle_) external virtual override onlyOperator {
        oracle = oracle_;
    }

    function getPrice() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1 ether;
        } else {
            return IOracle(oracle_).getPegPrice();
        }
    }

    function getPriceUpdated() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1 ether;
        } else {
            return IOracle(oracle_).getPegPriceUpdated();
        }
    }
}
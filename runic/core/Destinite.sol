// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../..//lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";

/**
 * @title Destinite
 */
contract Destinite is ERC20Burnable, AccessControlEnumerable, IERC20Burnable, IERC20Mintable {
    using SafeERC20 for IERC20;

    error NotOperator();

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    constructor() ERC20("DESTINITE", "DEST") {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function mint(address recipient_, uint256 amount_) public override onlyRole(AccessControlConstants.MINTER_ROLE) returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);
        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount_) public override(ERC20Burnable, IERC20Burnable) {
        super.burn(amount_);
    }

    function burnFrom(address account_, uint256 amount_) public override(ERC20Burnable, IERC20Burnable) {
        super.burnFrom(account_, amount_);
    }

    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        token_.safeTransfer(to_, amount_);
    }
}
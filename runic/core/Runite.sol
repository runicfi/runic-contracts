// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TaxableToken.sol";

/**
 * @title Runite
 */
contract Runite is TaxableToken {
    using SafeERC20 for IERC20;

    constructor(uint256 taxRate_, address taxCollectorAddress_) TaxableToken(taxRate_, taxCollectorAddress_) ERC20("RUNITE", "RUNITE") {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        // USDC is 6 decimals so the tier is different
        taxTiersTwaps = [0, 5e5, 6e5, 7e5, 8e5, 9e5, 9.5e5, 1e6, 1.05e6, 1.10e6, 1.20e6, 1.30e6, 1.40e6, 1.50e6];
        priceFloor = 0.9e6;
        burnThreshold = 1.10e6;
        _mint(msg.sender, 100 ether);
    }

    /**
     * @notice exclude an address from tax for to and from
     */
    function setExcludeAddress(address address_, bool exclude_) external onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        TaxableToken.excludedFromTaxAddresses[address_] = exclude_;
        TaxableToken.excludedToTaxAddresses[address_] = exclude_;
    }

    /**
     * @notice The base token is 6 decimals so the base should be 1e6 if no oracle is set
     */
    function getPrice() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1e6;
        } else {
            return IOracle(oracle_).getPegPrice();
        }
    }

    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        token_.safeTransfer(to_, amount_);
    }
}
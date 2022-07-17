// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../..//lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "./interfaces/IOracleToken.sol";
import "./interfaces/IVault.sol";

/**
 * @title RuniteVault
 * Allows exchange of Quartz to Runite when Runite is above claimPrice
 */
contract RuniteVault is AccessControlEnumerable, ReentrancyGuard, Pausable, IVault {
    using SafeERC20 for IERC20;
    address public claimToken;
    address public exchangeToken;
    uint256 public claimPrice;
    uint256 public claimed; // keeps track of total claimed
    uint256 public startTime;
    bool public started;

    error NotOperator();        // 0x7c214f04
    error PriceNotEligible();   // 0x91722c5f
    error Token();              // 0xc2412676
    error TooLate();            // 0xecdd1c29

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    constructor() {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IVault).interfaceId;
    }

    /**
     * @notice Sets tokens before start
     */
    function setTokens(address claimToken_, address exchangeToken_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        claimToken = claimToken_;
        exchangeToken = exchangeToken_;
    }

    /**
     * @notice Starts so cannot set claimToken or exchangeToken after
     */
    function start() external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        if(claimToken == address(0) || exchangeToken == address(0)) revert Token();
        started = true;
        startTime = block.timestamp;
    }

    /**
     * @notice Can only claim when above price target
     */
    function claim(uint256 amount_) external override whenNotPaused nonReentrant {
        uint256 price = IOracleToken(claimToken).getPriceUpdated();
        if(price < claimPrice) revert PriceNotEligible();

        IERC20Burnable(exchangeToken).burnFrom(msg.sender, amount_);
        IERC20Mintable(claimToken).mint(msg.sender, amount_);
        claimed += amount_;
    }

    function setClaimPrice(uint256 price_) external override onlyOperator {
        claimPrice = price_;
    }


    function setPause(bool pause_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        token_.safeTransfer(to_, amount_);
    }
}
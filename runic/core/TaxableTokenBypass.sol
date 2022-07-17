// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IOracleToken.sol";
import "./interfaces/INFTToken.sol";
import "./interfaces/ITaxableToken.sol";
import "../../dex/interfaces/IUniswapV2Router.sol";
import "../../lib/AccessControlConstants.sol";

/**
 * @title TaxableTokenBypass
 * Handles addliquidity without checks
 */
contract TaxableTokenBypass is AccessControlEnumerable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet _tokens;
    address public router;
    mapping(address => bool) public taxExclusionEnabled; // addresses excluded from tax

    error AmountCannotBeZero();
    error NotOperator();
    error Exist();
    error DoesNotExist();

    modifier onlyOperator {
        if(!AccessControl.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }

    constructor(address token_, address router_) {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        _tokens.add(token_);
        router = router_;
    }

    function addToken(address token_) external onlyOperator {
        if(_tokens.contains(token_)) revert Exist();
        _tokens.add(token_);
    }

    function removeToken(address token_) external onlyOperator {
        if(!_tokens.contains(token_)) revert DoesNotExist();
        _tokens.remove(token_);
    }

    function setRouter(address router_) external onlyOperator {
        router = router_;
    }

    function setPause(bool pause_) external onlyOperator {
        if(pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setExcludeFromAddressFromTax(address token_, address address_, bool exclude_) external onlyOperator {
        _setExcludeFromAddressFromTax(token_, address_, exclude_);
    }

    function _setExcludeFromAddressFromTax(address token_, address address_, bool exclude_) private {

        ITaxableToken(token_).setExcludeFromTaxAddress(address_, exclude_);
    }

    function setExcludeToAddressFromTax(address token_, address address_, bool exclude_) external onlyOperator {
        _setExcludeToAddressFromTax(token_, address_, exclude_);
    }

    function _setExcludeToAddressFromTax(address token_, address address_, bool exclude_) private {
        ITaxableToken(token_).setExcludeToTaxAddress(address_, exclude_);
    }

    function setExcludeFromNFTAddress(address token_, address address_, bool exclude_) external onlyOperator {
        _setExcludeFromNFTAddress(token_, address_, exclude_);
    }

    function _setExcludeFromNFTAddress(address token_, address address_, bool exclude_) private {
        INFTToken(token_).setExcludeFromNFTAddress(address_, exclude_);
    }

    function setExcludeToNFTAddress(address token_, address address_, bool exclude_) external onlyOperator {
        _setExcludeToNFTAddress(token_, address_, exclude_);
    }

    function _setExcludeToNFTAddress(address token_, address address_, bool exclude_) private {
        INFTToken(token_).setExcludeToNFTAddress(address_, exclude_);
    }

    /**
     * @notice Add liquidity tax free
     */
    function addLiquidity(address tokenA_, address tokenB_, uint256 amtTokenA_, uint256 amtTokenB_, uint256 amtTokenAMin_, uint256 amtTokenBMin_) external nonReentrant whenNotPaused returns (uint256, uint256, uint256) {
        if(amtTokenA_ == 0 || amtTokenB_ == 0) revert AmountCannotBeZero();
        // get existing exclusion
        // 0 = isExcludedA, 1 = isExcludedB, 2 = isExcludedNFTA, 3 = isExcludedNFTB
        bool[] memory isExcluded = new bool[](4);

        // tokenA
        if(_tokens.contains(tokenA_)) {
            if(ERC165Checker.supportsInterface(tokenA_, type(ITaxableToken).interfaceId)) {
                isExcluded[0] = ITaxableToken(tokenA_).isAddressFromTaxExcluded(msg.sender);
                _setExcludeFromAddressFromTax(tokenA_, msg.sender, true);
            }
            if(ERC165Checker.supportsInterface(tokenA_, type(INFTToken).interfaceId)) {
                isExcluded[2] = INFTToken(tokenA_).isAddressFromNFTExcluded(msg.sender);
                _setExcludeFromNFTAddress(tokenA_, msg.sender, true);
            }
        }
        // tokenB
        if(_tokens.contains(tokenB_)) {
            if(ERC165Checker.supportsInterface(tokenB_, type(ITaxableToken).interfaceId)) {
                isExcluded[1] = ITaxableToken(tokenB_).isAddressFromTaxExcluded(msg.sender);
                _setExcludeFromAddressFromTax(tokenB_, msg.sender, true);
            }
            if(ERC165Checker.supportsInterface(tokenB_, type(INFTToken).interfaceId)) {
                isExcluded[3] = INFTToken(tokenB_).isAddressFromNFTExcluded(msg.sender);
                _setExcludeFromNFTAddress(tokenB_, msg.sender, true);
            }
        }

        IERC20(tokenA_).safeTransferFrom(msg.sender, address(this), amtTokenA_);
        IERC20(tokenB_).safeTransferFrom(msg.sender, address(this), amtTokenB_);
        _approveTokenIfNeeded(tokenA_, router);
        _approveTokenIfNeeded(tokenB_, router);

        // tokenA
        if(_tokens.contains(tokenA_)) {
            if(!isExcluded[0]) {
                if(ERC165Checker.supportsInterface(tokenA_, type(ITaxableToken).interfaceId)) {
                    _setExcludeFromAddressFromTax(tokenA_, msg.sender, false);
                }
            }
            if(!isExcluded[2]) {
                if(ERC165Checker.supportsInterface(tokenA_, type(INFTToken).interfaceId)) {
                    _setExcludeFromNFTAddress(tokenA_, msg.sender, false);
                }
            }
        }
        // tokenB
        if(_tokens.contains(tokenB_)) {
            if(!isExcluded[1]) {
                if(ERC165Checker.supportsInterface(tokenB_, type(ITaxableToken).interfaceId)) {
                    _setExcludeFromAddressFromTax(tokenB_, msg.sender, false);
                }
            }
            if(!isExcluded[3]) {
                if(ERC165Checker.supportsInterface(tokenB_, type(INFTToken).interfaceId)) {
                    _setExcludeFromNFTAddress(tokenB_, msg.sender, false);
                }
            }
        }

        uint256 resultAmtTokenA;
        uint256 resultAmtTokenB;
        uint256 liquidity;
        (resultAmtTokenA, resultAmtTokenB, liquidity) = IUniswapV2Router(router).addLiquidity(
            tokenA_,
            tokenB_,
            amtTokenA_,
            amtTokenB_,
            amtTokenAMin_,
            amtTokenBMin_,
            msg.sender,
            block.timestamp
        );

        if(amtTokenA_ - resultAmtTokenA > 0) {
            IERC20(tokenA_).safeTransfer(msg.sender, amtTokenA_ - resultAmtTokenA);
        }
        if(amtTokenB_ - resultAmtTokenB > 0) {
            IERC20(tokenB_).safeTransfer(msg.sender, amtTokenB_ - resultAmtTokenB);
        }
        return (resultAmtTokenA, resultAmtTokenB, liquidity);
    }

    /**
     * @notice Add liquidity with ETH tax free
     */
    function addLiquidityETH(address tokenA_, uint256 amtTokenA_, uint256 amtTokenAMin_, uint256 amtEthMin_) external payable nonReentrant whenNotPaused returns (uint256, uint256, uint256) {
        if(amtTokenA_ == 0 || msg.value == 0) revert AmountCannotBeZero();

        // get existing exclusion
        bool isExcluded;
        bool isExcludedNFT;
        if(_tokens.contains(tokenA_)) {
            if(ERC165Checker.supportsInterface(tokenA_, type(ITaxableToken).interfaceId)) {
                isExcluded = ITaxableToken(tokenA_).isAddressFromTaxExcluded(msg.sender);
                _setExcludeFromAddressFromTax(tokenA_, msg.sender, true);
            }
            if(ERC165Checker.supportsInterface(tokenA_, type(INFTToken).interfaceId)) {
                isExcludedNFT = INFTToken(tokenA_).isAddressFromNFTExcluded(msg.sender);
                _setExcludeFromNFTAddress(tokenA_, msg.sender, true);
            }
        }

        IERC20(tokenA_).safeTransferFrom(msg.sender, address(this), amtTokenA_);
        _approveTokenIfNeeded(tokenA_, router);

        if(_tokens.contains(tokenA_)) {
            if(!isExcluded) {
                if(ERC165Checker.supportsInterface(tokenA_, type(ITaxableToken).interfaceId)) {
                    _setExcludeFromAddressFromTax(tokenA_, msg.sender, false);
                }
            }
            if(!isExcludedNFT) {
                if(ERC165Checker.supportsInterface(tokenA_, type(INFTToken).interfaceId)) {
                    _setExcludeFromNFTAddress(tokenA_, msg.sender, false);
                }
            }
        }

        uint256 resultAmtTokenA;
        uint256 resultAmtEth;
        uint256 liquidity;
        (resultAmtTokenA, resultAmtEth, liquidity) = IUniswapV2Router(router).addLiquidityETH{value: msg.value}(
            tokenA_,
            amtTokenA_,
            amtTokenAMin_,
            amtEthMin_,
            msg.sender,
            block.timestamp
        );

        if(amtTokenA_ - resultAmtTokenA > 0) {
            IERC20(tokenA_).safeTransfer(msg.sender, amtTokenA_ - resultAmtTokenA);
        }
        if(msg.value - resultAmtEth > 0 && address(this).balance > msg.value - resultAmtEth) {
            payable(msg.sender).transfer(msg.value - resultAmtEth);
        }
        return (resultAmtTokenA, resultAmtEth, liquidity);
    }

    function taxFreeTransferFrom(address token_, address sender_, address recipient_, uint256 amt_) external whenNotPaused {
        require(taxExclusionEnabled[msg.sender], "Address not approved for tax free transfers");

        // get existing exclusion
        bool isExcluded;
        bool isExcludedNFT;
        if(_tokens.contains(token_)) {
            if(ERC165Checker.supportsInterface(token_, type(ITaxableToken).interfaceId)) {
                isExcluded = ITaxableToken(token_).isAddressFromTaxExcluded(msg.sender);
                _setExcludeFromAddressFromTax(token_, msg.sender, true);
            }
            if(ERC165Checker.supportsInterface(token_, type(INFTToken).interfaceId)) {
                isExcludedNFT = INFTToken(token_).isAddressFromNFTExcluded(msg.sender);
                _setExcludeFromNFTAddress(token_, msg.sender, true);
            }
        }

        IERC20(token_).safeTransferFrom(sender_, recipient_, amt_);

        if(_tokens.contains(token_)) {
            if(!isExcluded) {
                if(ERC165Checker.supportsInterface(token_, type(ITaxableToken).interfaceId)) {
                    _setExcludeFromAddressFromTax(token_, msg.sender, false);
                }
            }
            if(!isExcludedNFT) {
                if(ERC165Checker.supportsInterface(token_, type(INFTToken).interfaceId)) {
                    _setExcludeFromNFTAddress(token_, msg.sender, false);
                }
            }
        }
    }

    function setTaxExclusionForAddress(address address_, bool excluded_) external onlyOperator {
        taxExclusionEnabled[address_] = excluded_;
    }

    function _approveTokenIfNeeded(address token_, address router_) private {
        if(IERC20(token_).allowance(address(this), router_) == 0) {
            IERC20(token_).safeApprove(router_, type(uint256).max);
        }
    }
}
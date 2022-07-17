// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../dex/interfaces/IUniswapV2Pair.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";
import "./interfaces/ITaxableToken.sol";
import "./OracleToken.sol";

/**
 * @title TaxableToken
 */
abstract contract TaxableToken is ERC20Burnable, OracleToken, IERC20Burnable, IERC20Mintable, ITaxableToken {
    address public taxCollectorAddress;
    address public liquidityPair;           // main liquidity pair
    uint256 public override taxRate;        // current tax rate
    uint256 public burnThreshold = 1.10e18; // price threshold below which taxes will get burned
    uint256 public totalBurned;
    uint256 public override priceFloor = 0.9e17; // to block sell
    uint256 public override priceCeiling; // if price goes below then only allow sell trough authorized contract such as marketplace. Disabled until implemented
    uint256 public sellCeilingSupplyRate = 10; // up to 0.1% supply for each sell
    uint256 public sellCeilingLiquidityRate = 50; // up to 0.5% in liquidity for each sell
    bool public autoCalculateTax;           // should the taxes be calculated using the tax tiers
    // tax tiers
    uint256[] public taxTiersTwaps = [0, 5e17, 6e17, 7e17, 8e17, 9e17, 9.5e17, 1e18, 1.05e18, 1.10e18, 1.20e18, 1.30e18, 1.40e18, 1.50e18];
    // tax rates in 10000 base. ex: 2000 = 20% 100 = 1%
    uint256[] public taxTiersRates = [2000, 1900, 1800, 1700, 1600, 1500, 1500, 1500, 1500, 1400, 900, 400, 200, 100];
    mapping(address => bool) public excludedFromTaxAddresses; // sender addresses excluded from tax such as contracts or liquidity pairs
    mapping(address => bool) public excludedToTaxAddresses; // receiver addresses excluded from tax
    mapping(address => bool) public whitelistAddresses; // address allowed to sell when below priceCeiling. Reserved for contracts

    error AutoCalculateTaxOn();
    error TaxTooHigh();
    error PriceTooHigh();
    error PriceTooLow();
    error AmountTooHigh();
    error AccountNotAuthorizedToSell();

    constructor(uint256 taxRate_, address taxCollectorAddress_) {
        if(taxRate_ >= 10000) revert TaxTooHigh();
        if(taxCollectorAddress_ == address(0)) revert ZeroAddress();
        excludedFromTaxAddresses[address(this)] = true;
        taxRate = taxRate_;
        taxCollectorAddress = taxCollectorAddress_;
        excludedFromTaxAddresses[msg.sender] = true;
        excludedFromTaxAddresses[address(0)] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC20Burnable).interfaceId ||
        interfaceId == type(IERC20Mintable).interfaceId ||
        interfaceId == type(ITaxableToken).interfaceId;
    }

    function isAddressFromTaxExcluded(address address_) external view virtual override returns (bool) {
        return excludedFromTaxAddresses[address_];
    }

    function isAddressToTaxExcluded(address address_) external view virtual override returns (bool) {
        return excludedToTaxAddresses[address_];
    }

    function setTaxCollectorAddress(address taxCollectorAddress_) external virtual override onlyOperator {
        if(taxCollectorAddress_ == address(0)) revert ZeroAddress();
        taxCollectorAddress = taxCollectorAddress_;
    }

    function setTaxTiersTwap(uint8 index_, uint256 value_) external virtual override onlyOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= taxTiersTwaps.length) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > taxTiersTwaps[index_ - 1]);
        }
        if(index_ < (taxTiersTwaps.length - 1)) {
            require(value_ < taxTiersTwaps[index_ + 1]);
        }
        taxTiersTwaps[index_] = value_;
    }

    function setTaxTiersRate(uint8 index_, uint256 value_) external virtual override onlyOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= taxTiersRates.length) revert IndexTooHigh();
        taxTiersRates[index_] = value_;
    }

    function setAutoCalculateTax(bool enable_) external virtual override onlyOperator {
        autoCalculateTax = enable_;
    }

    function setTaxRate(uint256 taxRate_) external virtual override onlyOperator {
        if(autoCalculateTax) revert AutoCalculateTaxOn();
        if(taxRate_ >= 10000) revert TaxTooHigh();
        taxRate = taxRate_;
    }

    function setBurnThreshold(uint256 burnThreshold_) external virtual override onlyOperator {
        burnThreshold = burnThreshold_;
    }

    function setPriceFloor(uint256 priceFloor_) external virtual override onlyOperator {
        priceFloor = priceFloor_;
    }

    function setPriceCeiling(uint256 priceCeiling_) external virtual override onlyOperator {
        priceCeiling = priceCeiling_;
    }

    function setSellCeilingSupplyRate(uint256 sellCeilingSupplyRate_) external virtual override onlyOperator {
        sellCeilingSupplyRate = sellCeilingSupplyRate_;
    }

    function setSellCeilingLiquidityRate(uint256 sellCeilingLiquidityRate_) external virtual override onlyOperator {
        sellCeilingLiquidityRate = sellCeilingLiquidityRate_;
    }

    function setLiquidityPair(address liquidityPair_) external virtual onlyOperator {
        liquidityPair = liquidityPair_;
    }

    function setExcludeFromTaxAddress(address address_, bool exclude_) external virtual override onlyOperator {
        excludedFromTaxAddresses[address_] = exclude_;
    }

    function setExcludeToTaxAddress(address address_, bool exclude_) external virtual override onlyOperator {
        excludedToTaxAddresses[address_] = exclude_;
    }

    function setWhitelistAddress(address address_, bool whitelist_) external virtual override onlyOperator {
        whitelistAddresses[address_] = whitelist_;
    }

    function getTaxRate() external view virtual override returns (uint256 rate) {
        uint256 currentPrice = OracleToken.getPriceUpdated();
        if(autoCalculateTax) {
            for(uint8 tierId = uint8(taxTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(currentPrice >= taxTiersTwaps[tierId]) {
                    if(taxTiersRates[tierId] >= 10000) revert TaxTooHigh();
                    return taxTiersRates[tierId];
                }
            }
        }
        return taxRate;
    }

    function _updateTaxRate(uint256 price_) internal virtual returns (uint256) {
        if(autoCalculateTax) {
            for(uint8 tierId = uint8(taxTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(price_ >= taxTiersTwaps[tierId]) {
                    if(taxTiersRates[tierId] >= 10000) revert TaxTooHigh();
                    taxRate = taxTiersRates[tierId];
                    return taxTiersRates[tierId];
                }
            }
        }
        return taxRate;
    }

    function sellingLimit() public view override returns (uint256) {
        uint256 _limitBySupply = (totalSupply() * sellCeilingSupplyRate) / 10000;
        uint256 _reserveAmount = _getAmountInReserves();
        if (_reserveAmount == 0) return _limitBySupply;
        uint256 _limitByLiquidity = (_reserveAmount * sellCeilingLiquidityRate) / 10000;
        return (_limitBySupply > _limitByLiquidity) ? _limitByLiquidity : _limitBySupply;
    }

    function _getAmountInReserves() internal view returns (uint256 reserve) {
        address pair = liquidityPair;
        if(pair != address(0)) {
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
            if(IUniswapV2Pair(pair).token0() == address(this)) {
                reserve = reserve0;
            } else {
                reserve = reserve1;
            }
        }
        return reserve;
    }

    function mint(address to_, uint256 amount_) external virtual override onlyRole(AccessControlConstants.MINTER_ROLE) returns (bool) {
        uint256 balanceBefore = balanceOf(to_);
        _mint(to_, amount_);
        uint256 balanceAfter = balanceOf(to_);
        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount_) public virtual override(ERC20Burnable, IERC20Burnable) {
        super.burn(amount_);
    }

    function burnFrom(address account_, uint256 amount_) public virtual override(ERC20Burnable, IERC20Burnable) {
        super.burnFrom(account_, amount_);
    }

    function _transfer(address from_, address to_, uint256 amount_) internal virtual override {
        uint256 currentTaxRate;
        bool burnTax = false;
        uint256 currentPrice = OracleToken.getPriceUpdated();

        if(autoCalculateTax) {
            currentTaxRate = _updateTaxRate(currentPrice);
            if(currentPrice < burnThreshold) {
                burnTax = true;
            }
        }

        if(currentTaxRate == 0 || excludedFromTaxAddresses[from_] || excludedToTaxAddresses[to_]) {
            super._transfer(from_, to_, amount_);
        } else {
            if(currentPrice <= priceFloor) revert PriceTooLow();
            if(amount_ > sellingLimit()) revert AmountTooHigh();
            // if price < price certain threshold, sell only allowed through authorized contract such as a marketplace
            if(currentPrice <= priceCeiling && !whitelistAddresses[msg.sender]) revert AccountNotAuthorizedToSell();

            // transfer with tax
            uint256 taxAmount = (amount_ * taxRate) / 10000;
            uint256 amountAfterTax = amount_ - taxAmount;

            if(burnTax) {
                // Burn tax
                super._burn(from_, taxAmount);
            } else {
                // Transfer tax to tax collector
                super._transfer(from_, taxCollectorAddress, taxAmount);
            }

            // Transfer amount after tax to recipient
            super._transfer(from_, to_, amountAfterTax);
        }
    }

    function _burn(address from_, uint256 amount_) internal virtual override {
        totalBurned += amount_;
        super._burn(from_, amount_);
    }
}
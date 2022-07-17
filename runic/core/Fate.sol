// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NFTToken.sol";
import "./TaxableToken.sol";

/**
 * @title Fate
 * Total max supply = 100,000
 * Funds and vault handles minting
 * Mint and burn function is needed for a MINT/BURN bridge which may be added in the future
 */
contract Fate is TaxableToken, NFTToken {
    using SafeERC20 for IERC20;
    // TOTAL MAX SUPPLY = 100,000
    uint256 public constant TOTAL_MAX_SUPPLY = 100_000 ether;
    uint256 public constant VAULT_ALLOCATION = 50000 ether;
    uint256 public constant FUND_ALLOCATION = 50000 ether;

    error MaxSupply();

    constructor(uint256 taxRate_, address taxCollectorAddress_) TaxableToken(taxRate_, taxCollectorAddress_) ERC20("FATE", "FATE") {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        nftTiersTwaps = [0, 900e18, 920e18, 940e18, 960e18, 980e18, 990e18, 1000e18, 1010e18, 1020e18, 1040e18, 1060e18, 1080e18, 1100e18];
        taxTiersTwaps = [0, 900e18, 920e18, 940e18, 960e18, 980e18, 990e18, 1000e18, 1010e18, 1020e18, 1040e18, 1060e18, 1080e18, 1100e18];
        priceFloor = 500e18;
        burnThreshold = 1010e18;

        TaxableToken.excludedFromTaxAddresses[msg.sender] = true;
        NFTToken.excludedFromNFTAddresses[msg.sender] = true;

        _mint(msg.sender, 100 ether); // deployer
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(TaxableToken, NFTToken) returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC20Burnable).interfaceId ||
        interfaceId == type(IERC20Mintable).interfaceId ||
        interfaceId == type(ITaxableToken).interfaceId ||
        interfaceId == type(INFTToken).interfaceId;
    }

    /**
     * @notice exclude an address from both tax and nft power requirement for to and from
     */
    function setExcludeAddress(address address_, bool exclude_) external onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        TaxableToken.excludedFromTaxAddresses[address_] = exclude_;
        TaxableToken.excludedToTaxAddresses[address_] = exclude_;
        NFTToken.excludedFromNFTAddresses[address_] = exclude_;
        NFTToken.excludedToNFTAddresses[address_] = exclude_;
    }

    function getPrice() public view virtual override returns (uint256 price) {
        address oracle_ = oracle;
        if(oracle_ == address(0)) {
            return 1000 ether;
        } else {
            return IOracle(oracle_).getPegPrice();
        }
    }

    function _transfer(address from_, address to_, uint256 amount_) internal virtual override(ERC20, TaxableToken) {
        TaxableToken._transfer(from_, to_, amount_);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual override(ERC20, NFTToken) {
        NFTToken._beforeTokenTransfer(from_, to_, amount_);
    }

    function _mint(address to_, uint256 amount_) internal virtual override {
        if(totalSupply() + amount_ >= TOTAL_MAX_SUPPLY) revert MaxSupply();
        super._mint(to_, amount_);
    }

    function _burn(address from_, uint256 amount_) internal virtual override(ERC20, TaxableToken) {
        TaxableToken._burn(from_, amount_);
    }

    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        token_.safeTransfer(to_, amount_);
    }
}
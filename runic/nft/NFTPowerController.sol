// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "./interfaces/INFTPower.sol";

/**
 * @title NFTPowerController
 */
contract NFTPowerController is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    EnumerableSetUpgradeable.AddressSet private _nftContracts;  // supported nft contracts
    EnumerableSetUpgradeable.AddressSet private _erc20Currency; // supported erc20 currency
    uint256 public price; // price payable
    mapping(address => uint256) public erc20Price; // price with supported erc20 currency
    address public feeAddress;
    address public erc20FeeAddress;

    error DoesNotExist();       // 0xb0ce7591
    error ERC20NotSupported();  // 0x60c87f0d
    error Exist();              // 0x65956805
    error Fee();                // 0xbef7a2f0
    error NFTNotSupported();    // 0xa45e82f5
    error NotNFTOwner();        // 0x4088c61c
    error PowerTooLow();        // 0xdb7c7c96

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address nftContract_, uint256 price_, address erc20Currency_, uint256 erc20Price_) public initializer {
        __NFTPowerController_init(nftContract_, price_, erc20Currency_, erc20Price_);
    }

    function __NFTPowerController_init(address nftContract_, uint256 price_, address erc20Currency_, uint256 erc20Price_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __NFTPowerController_init_unchained(nftContract_, price_, erc20Currency_, erc20Price_);
    }

    function __NFTPowerController_init_unchained(address nftContract_, uint256 price_, address erc20Currency_, uint256 erc20Price_) internal onlyInitializing {
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        feeAddress = msg.sender;
        erc20FeeAddress = msg.sender;
        _nftContracts.add(nftContract_);
        price = price_;
        _erc20Currency.add(erc20Currency_);
        erc20Price[erc20Currency_] = erc20Price_;
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    receive() external payable {}
    fallback() external payable {}

    /**
     * @notice Add power to nft
     */
    function addPower(address nftContract_, uint256 tokenId_, uint256 power_) external payable nonReentrant whenNotPaused {
        if(!_nftContracts.contains(nftContract_)) revert NFTNotSupported();
        if(msg.value < price * power_) revert Fee();
        if(IERC721(nftContract_).ownerOf(tokenId_) != msg.sender) revert NotNFTOwner();
        INFTPower(nftContract_).addPower(msg.sender, tokenId_, power_);
        (bool sent,) = payable(feeAddress).call{value: address(this).balance}("");
        require(sent);
    }

    function addPowerWithERC20(address nftContract_, uint256 tokenId_, uint256 power_, address erc20_) external nonReentrant whenNotPaused {
        if(!_nftContracts.contains(nftContract_)) revert NFTNotSupported();
        if(!_erc20Currency.contains(erc20_)) revert ERC20NotSupported();
        if(erc20Price[erc20_] > 0) {
            // burn token
            // fee address must be excluded to for tax and checks
            // IERC20(erc20_).transferFrom(msg.sender, erc20FeeAddress, erc20Price[erc20_] * power_);
            IERC20Burnable(erc20_).burnFrom(msg.sender, erc20Price[erc20_] * power_);
        }
        if(IERC721(nftContract_).ownerOf(tokenId_) != msg.sender) revert NotNFTOwner();
        INFTPower(nftContract_).addPower(msg.sender, tokenId_, power_);
    }

    function removePower(address nftContract_, uint256 tokenId_, uint256 power_) external nonReentrant whenNotPaused {
        if(!_nftContracts.contains(nftContract_)) revert NFTNotSupported();
        if(IERC721(nftContract_).ownerOf(tokenId_) != msg.sender) revert NotNFTOwner();
        // make sure power removal will not result in less than 0
        uint256 currentPower = INFTPower(nftContract_).getPower(tokenId_);
        if(currentPower < power_) revert PowerTooLow();
        INFTPower(nftContract_).removePower(msg.sender, tokenId_, power_);
    }

    function addNFTContract(address nftContract_) external onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        if(_nftContracts.contains(nftContract_)) revert Exist();
        _nftContracts.add(nftContract_);
    }

    function removeNFTContract(address nftContract_) external onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        if(!_nftContracts.contains(nftContract_)) revert DoesNotExist();
        _nftContracts.remove(nftContract_);
    }

    function getNFTContracts() external view returns(address[] memory) {
        return _nftContracts.values();
    }

    function setPrice(uint256 price_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        price = price_;
    }

    function setERC20Price(address erc20_, uint256 price_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        erc20Price[erc20_] = price_;
    }

    function addERC20Currency(address erc20Currency_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _erc20Currency.add(erc20Currency_);
    }

    function removeERC20Currency(address erc20Currency_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _erc20Currency.remove(erc20Currency_);
    }

    function getERC20Currency() external view returns (address[] memory) {
        return _erc20Currency.values();
    }

    function setFeeAddress(address feeAddress_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        feeAddress = feeAddress_;
    }

    function setERC20FeeAddress(address feeAddress_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        erc20FeeAddress = feeAddress_;
    }

    function setPause(bool pause_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function withdraw() external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }

    function withdrawERC20Token(address token_, uint256 amount_) external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token_).safeTransfer(msg.sender, amount_);
    }
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../nft/interfaces/ITokenURIProcessor.sol";
import "../../nft/NFTERC721Upgradeable.sol";
import "./lib/RunicNFTLib.sol";
import "./interfaces/INFTStats.sol";
import "./interfaces/IRunicNFT.sol";
import "./interfaces/IOperatorBurn.sol";

/**
 * @title RunesNFT
 */
contract RunesNFT is Initializable, UUPSUpgradeable, NFTERC721Upgradeable, INFTStats, IOperatorBurn, IRunicNFT {
    mapping(uint256 => RunicNFTLib.RunicAttributes) private _runicAttributes;
    mapping(uint256 => uint256) private _power;     // power of token
    mapping(address => uint256) private _userPower; // total power of user
    uint256 private _totalPower;                    // total power of all tokens

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __RunesNFT_init();
    }

    function __RunesNFT_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained("Runic Runes", "RUNES");
        __ERC721Burnable_init_unchained();
        __ERC721Enumerable_init_unchained();
        __NFT_init_unchained();
        __NFTERC721_init_unchained();
        __RunesNFT_init_unchained();
    }

    function __RunesNFT_init_unchained() internal onlyInitializing {}

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(INFTStats).interfaceId ||
        interfaceId == type(INFTAwakening).interfaceId ||
        interfaceId == type(INFTLevel).interfaceId ||
        interfaceId == type(INFTPower).interfaceId ||
        interfaceId == type(INFTPromotion).interfaceId ||
        interfaceId == type(INFTRarity).interfaceId ||
        interfaceId == type(IOperatorBurn).interfaceId ||
        interfaceId == type(IRunicNFT).interfaceId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) revert NonExistentToken();

        string memory _tokenURI = _tokenURIs[tokenId];

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI(), _tokenURI));
        }

        return ITokenURIProcessor(_addressMapping[NFTConstants.ADDR_MAPPING_TOKEN_URI_PROCESSOR]).getTokenURI(tokenId);
    }

    function setTokenURIProcessor(address tokenURIProcessor_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _addressMapping[NFTConstants.ADDR_MAPPING_TOKEN_URI_PROCESSOR] = tokenURIProcessor_;
    }

    function setRoyaltyInfo(address receiver_, uint256 amount_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _addressMapping[NFTConstants.ADDR_MAPPING_ROYALTY_RECEIVER] = receiver_;
        _uintMapping[NFTConstants.UINT_MAPPING_ROYALTY_AMOUNT] = amount_;
    }

    function setRunicAttributes(uint256 tokenId_, RunicNFTLib.RunicAttributes memory attributes_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _runicAttributes[tokenId_] = attributes_;
    }

    function getRunicAttributes(uint256 tokenId_) external view override returns (RunicNFTLib.RunicAttributes memory) {
        return _runicAttributes[tokenId_];
    }

    function getPower(uint256 tokenId_) external view override returns (uint256 power) {
        return _power[tokenId_];
    }

    function getUserPower(address account_) external view override returns (uint256 power) {
        return _userPower[account_];
    }

    function getTotalPower() external view override returns (uint256 power) {
        return _totalPower;
    }

    function getLevel(uint256 tokenId_) external view override returns (uint32 level) {
        return _runicAttributes[tokenId_].level;
    }

    function getRarity(uint256 tokenId_) external view override returns (uint32 rarity) {
        return _runicAttributes[tokenId_].rarityId;
    }

    function getPromotion(uint256 tokenId_) external view override returns (uint32 promotion) {
        return _runicAttributes[tokenId_].promotion;
    }

    function getAwakening(uint256 tokenId_) external view override returns (uint32 awakening) {
        return _runicAttributes[tokenId_].awakening;
    }

    function getStats(uint256 tokenId_) external view override returns (NFTStatsLib.Stats memory stats) {
        RunicNFTLib.RunicAttributes memory attributes = _runicAttributes[tokenId_];
        stats.level = attributes.level;
        stats.rarity = attributes.rarityId;
        stats.promotion = attributes.promotion;
        stats.awakening = attributes.awakening;
        stats.power = _power[tokenId_];
        return stats;
    }

    function setLevel(uint256 tokenId_, uint32 level_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _runicAttributes[tokenId_].level = level_;
    }

    function setPromotion(uint256 tokenId_, uint32 promotion_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _runicAttributes[tokenId_].promotion = promotion_;
    }

    function setAwakening(uint256 tokenId_, uint32 awakening_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _runicAttributes[tokenId_].awakening = awakening_;
    }

    function addPower(address account_, uint256 tokenId_, uint256 power_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _power[tokenId_] += power_;
        _userPower[account_] += power_;
        _totalPower += power_;
    }

    function removePower(address account_, uint256 tokenId_, uint256 power_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        _power[tokenId_] -= power_;
        _userPower[account_] -= power_;
        _totalPower -= power_;
    }

    function operatorBurn(uint256 tokenId) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        uint256 power = _power[tokenId];
        _userPower[from] -= power;
        if(to != address(0)) {
            _userPower[to] += power;
        } else {
            _totalPower -= power;
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
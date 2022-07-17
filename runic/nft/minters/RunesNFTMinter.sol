// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../../lib/AccessControlConstants.sol";
import "../../../nft/interfaces/INFTMintable.sol";
import "../../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../../token/ERC721/extensions/IERC721Burnable.sol";
import "../../../nft/interfaces/INFTAttributes.sol";
import "../lib/RunesNFTConstants.sol";
import "../interfaces/INFTMaxSupply.sol";
import "../interfaces/INFTPower.sol";
import "../interfaces/IRunicNFT.sol";
import "../interfaces/IRunesNFTMinter.sol";

/**
 * @title RunesNFTMinter
 */
contract RunesNFTMinter is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable, INFTMaxSupply, IRunesNFTMinter {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public override(INFTMaxSupply, IRunesNFTMinter) maxSupply;
    uint256 public combinePrice;
    address public runesNFT;
    uint256[] public priceTiersSupply;
    uint256[] public priceTiersValue;
    uint256 public mintCount;
    uint256 public craftCount;

    event Crafted(uint256 tokenId, uint256[] ingredientIds, address user, uint256 timestamp);
    event Minted(uint256 tokenId, address user, uint256 timestamp);

    error ERC20NotSupported();          // 0x60c87f0d
    error Fee();                        // 0xbef7a2f0
    error IndexTooHigh();               // 0xfbf22ac0
    error IndexTooLow();                // 0x9d445a78
    error InvalidElement();             // 0x1bdcf416
    error Locked();                     // 0x0f2e5b6c
    error MaxSupply();                  // 0xb36c1284
    error NumRunesRequired(uint256);    // 0xefdbd859
    error NotOwner();                   // 0x30cd7471
    error RarityRequired(uint256);      // 0x8ab8c5e1

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address runesNFT_, uint256 mintCount_, uint256 craftCount_) public initializer {
        __RunesNFTMinter_init(runesNFT_, mintCount_, craftCount_);
    }

    function __RunesNFTMinter_init(address runesNFT_, uint256 mintCount_, uint256 craftCount_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __RunesNFTMinter_init_unchained(runesNFT_, mintCount_, craftCount_);
    }

    function __RunesNFTMinter_init_unchained(address runesNFT_, uint256 mintCount_, uint256 craftCount_) internal onlyInitializing {
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.MINTER_ROLE, msg.sender);
        runesNFT = runesNFT_;
        mintCount = mintCount_;
        craftCount = craftCount_;
        maxSupply = 10000;
        combinePrice = 5 ether;
        priceTiersSupply = [0, 100, 200, 400, 800, 1600, 3200, 6400, 9000];
        priceTiersValue = [100 ether, 150 ether, 200 ether, 250 ether, 300 ether, 350 ether, 400 ether, 450 ether, 500 ether];
        _pause();
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    receive() external payable {}
    fallback() external payable {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(INFTMaxSupply).interfaceId ||
        interfaceId == type(IRunesNFTMinter).interfaceId;
    }

    function getPrice() public view returns (uint256 price_) {
        uint256 supply = IERC721Enumerable(runesNFT).totalSupply();
        for(uint8 tierId = uint8(priceTiersSupply.length) - 1; tierId >= 0; tierId--) {
            if(supply >= priceTiersSupply[tierId]) {
                return priceTiersValue[tierId];
            }
        }
        return 0;
    }

    /**
     * @notice Default method to buy
     */
    function buy(uint256 amount_) external payable whenNotPaused nonReentrant {
        if(msg.value < getPrice() * amount_) revert Fee();
        for(uint256 i; i < amount_; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to_) internal {
        if(IERC721Enumerable(runesNFT).totalSupply() >= maxSupply) revert MaxSupply();
        uint256 id_ = INFTMintable(runesNFT).mint(to_);
        _setAttributes(id_, _random(1, 1000), getRandomElementId());
        INFTPower(runesNFT).addPower(to_, id_, 1);
        mintCount++;
        emit Minted(id_, to_, block.timestamp);
    }

    /**
     * @notice Mint without paying fee
     */
    function freeMint(address to_, uint256 amount_) external override onlyRole(AccessControlConstants.MINTER_ROLE) {
        for(uint256 i; i < amount_; i++) {
            safeMint(to_);
        }
    }

    /**
     * @notice Mint specific attributes through operator
     * supply is checked in operator contract
     */
    function mintSpecific(address to_, RunicNFTLib.RunicAttributes memory attributes_) external override onlyRole(AccessControlConstants.MINTER_ROLE) returns (uint256) {
        uint256 id_ = INFTMintable(runesNFT).mint(to_);
        IRunicNFT(runesNFT).setRunicAttributes(id_, attributes_);
        INFTPower(runesNFT).addPower(to_, id_, 1);
        mintCount++;
        emit Minted(id_, to_, block.timestamp);
        return id_;
    }

    /**
     * @notice Mint without supply check through operator
     */
    function mintExtra(address to_) external override onlyRole(AccessControlConstants.MINTER_ROLE) returns (uint256) {
        uint256 id_ = INFTMintable(runesNFT).mint(to_);
        _setAttributes(id_, _random(1, 1000), getRandomElementId());
        INFTPower(runesNFT).addPower(to_, id_, 1);
        mintCount++;
        emit Minted(id_, to_, block.timestamp);
        return id_;
    }

    function combineCommonRunes(uint256[] memory tokenIds_) external payable whenNotPaused nonReentrant {
        if(msg.value < combinePrice) revert Fee();
        _combineCommonRunes(tokenIds_);
    }

    /**
     * @notice burns 5 common runes to mint a rarer rune
     */
    function _combineCommonRunes(uint256[] memory tokenIds_) internal {
        if(tokenIds_.length != 5) revert NumRunesRequired(5);
        if(IERC721Enumerable(runesNFT).totalSupply() - 5 >= maxSupply) revert MaxSupply();
        for(uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if(IERC721(runesNFT).ownerOf(tokenId) != msg.sender) revert NotOwner();
            if(IRunicNFT(runesNFT).getRunicAttributes(tokenId).rarityId != RunesNFTConstants.RARITY_COMMON) revert RarityRequired(0);
            if(INFTAttributes(runesNFT).getAttribute(RunesNFTConstants.UINT_LOCKED, tokenId) == 1) revert Locked();
            IERC721Burnable(runesNFT).burn(tokenId);
        }
        uint256 id = INFTMintable(runesNFT).mint(msg.sender);
        uint256 random = _random(1, 1000);
        uint32 elementId = getRandomElementId();
        if(random <= 50) {
            // legendary - 5%
            _setAttributes(id, 20, elementId);
        } else if(random <= 200) {
            // epic - 15%
            _setAttributes(id, 100, elementId);
        } else {
            // rare - 80%
            _setAttributes(id, 250, elementId);
        }
        mintCount++;
        craftCount++;
        emit Minted(id, msg.sender, block.timestamp);
        emit Crafted(id, tokenIds_, msg.sender, block.timestamp);
    }

    function combineRareRunes(uint256[] memory tokenIds_) external payable whenNotPaused nonReentrant {
        if(msg.value < combinePrice) revert Fee();
        _combineRareRunes(tokenIds_);
    }

    /**
     * @notice burns 5 rare runes to mint a rarer rune
     * the more of the same element rune used the higher chance of same element rune
     */
    function _combineRareRunes(uint256[] memory tokenIds_) internal {
        if(tokenIds_.length != 5) revert NumRunesRequired(5);
        if(IERC721Enumerable(runesNFT).totalSupply() - 5 >= maxSupply) revert MaxSupply();
        uint256[5] memory elementPool;
        for(uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if(IERC721(runesNFT).ownerOf(tokenId) != msg.sender) revert NotOwner();
            if(IRunicNFT(runesNFT).getRunicAttributes(tokenId).rarityId != RunesNFTConstants.RARITY_RARE) revert RarityRequired(1);
            if(INFTAttributes(runesNFT).getAttribute(RunesNFTConstants.UINT_LOCKED, tokenId) == 1) revert Locked();
            IERC721Burnable(runesNFT).burn(tokenId);
            elementPool[i] = uint256(IRunicNFT(runesNFT).getRunicAttributes(tokenId).elementId);
        }
        uint32 elementId = uint32(elementPool[_random(0, 4)]);
        if(elementId == 0) revert InvalidElement();
        uint256 id = INFTMintable(runesNFT).mint(msg.sender);
        uint256 random = _random(1, 1000);
        if(random <= 100) {
            // legendary - 10%
            _setAttributes(id, 20, elementId);
        } else {
            // epic - 90%
            _setAttributes(id, 100, elementId);
        }
        mintCount++;
        craftCount++;
        emit Minted(id, msg.sender, block.timestamp);
        emit Crafted(id, tokenIds_, msg.sender, block.timestamp);
    }

    function combineEpicRunes(uint256[] memory tokenIds_) external payable whenNotPaused nonReentrant {
        if(msg.value < combinePrice) revert Fee();
        _combineEpicRunes(tokenIds_);
    }

    /**
     * @notice burns 5 epic runes to mint a rarer rune
     * the more of the same element rune used the higher chance of same element rune
     */
    function _combineEpicRunes(uint256[] memory tokenIds_) internal {
        if(tokenIds_.length != 5) revert NumRunesRequired(5);
        if(IERC721Enumerable(runesNFT).totalSupply() - 5 >= maxSupply) revert MaxSupply();
        uint256[5] memory elementPool;
        for(uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if(IERC721(runesNFT).ownerOf(tokenId) != msg.sender) revert NotOwner();
            if(IRunicNFT(runesNFT).getRunicAttributes(tokenId).rarityId != RunesNFTConstants.RARITY_EPIC) revert RarityRequired(2);
            if(INFTAttributes(runesNFT).getAttribute(RunesNFTConstants.UINT_LOCKED, tokenId) == 1) revert Locked();
            IERC721Burnable(runesNFT).burn(tokenId);
            elementPool[i] = uint256(IRunicNFT(runesNFT).getRunicAttributes(tokenId).elementId);
        }
        uint32 elementId = uint32(elementPool[_random(0, 4)]);
        if(elementId == 0) revert InvalidElement();
        uint256 id = INFTMintable(runesNFT).mint(msg.sender);
        // legendary - 100%
        _setAttributes(id, 20, elementId);
        mintCount++;
        craftCount++;
        emit Minted(id, msg.sender, block.timestamp);
        emit Crafted(id, tokenIds_, msg.sender, block.timestamp);
    }

    /**
     * @notice Set attributes
     */
    function _setAttributes(uint256 id_, uint256 rarity_, uint32 elementId_) internal {
        RunicNFTLib.RunicAttributes memory attributes;
        if(rarity_ <= 20) {
            // legendary - 2%
            attributes.rarityId = RunesNFTConstants.RARITY_LEGENDARY;
            attributes.elementId = elementId_;
            attributes.backgroundId = 4000 + (attributes.elementId - 1) * 10;
            attributes.bodyId = 4000 + (attributes.elementId - 1) * 10;
        } else if(rarity_ <= 100) {
            // epic - 8%
            attributes.rarityId = RunesNFTConstants.RARITY_EPIC;
            attributes.elementId = elementId_;
            attributes.backgroundId = 3000 + ((attributes.elementId - 1) * 10) + uint32(_random(0, 1));
            attributes.bodyId = 3000 + ((attributes.elementId - 1) * 10) + uint32(_random(0, 1));
        } else if(rarity_ <= 250) {
            // rare - 15%
            attributes.rarityId = RunesNFTConstants.RARITY_RARE;
            attributes.elementId = elementId_;
            attributes.backgroundId = uint32(_random(1, 14));
            attributes.bodyId = 1000 + ((attributes.elementId - 1) * 100) + uint32(_random(1, 28));
        } else {
            // common - 75%
            // attributes.rarityId = RunesNFTConstants.RARITY_COMMON;
            attributes.backgroundId = uint32(_random(1, 14));
            attributes.bodyId = uint32(_random(1, 28));
        }
        IRunicNFT(runesNFT).setRunicAttributes(id_, attributes);
    }

    /**
     * @notice returns random element all with equal chance
     */
    function getRandomElementId() internal view returns (uint32) {
        return uint32(_random(RunesNFTConstants.ELEMENT_ID_NEUTRAL, RunesNFTConstants.ELEMENT_ID_AETHER));
    }

    function _random(uint256 min_, uint256 max_) internal view returns (uint256) {
        max_++;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, gasleft()))) % (max_ - min_);
        randomNumber = randomNumber + min_;
        return randomNumber;
    }

    function setPause(bool pause_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setMaxSupply(uint256 maxSupply_) external override onlyRole(AccessControlConstants.OPERATOR_ROLE) {
        maxSupply = maxSupply_;
    }

    function setPriceTiersSupply(uint8 index_, uint256 value_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= priceTiersSupply.length) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > priceTiersSupply[index_ - 1]);
        }
        if(index_ < (priceTiersSupply.length - 1)) {
            require(value_ < priceTiersSupply[index_ + 1]);
        }
        priceTiersSupply[index_] = value_;
    }

    function setPriceTiersValue(uint8 index_, uint256 value_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= priceTiersValue.length) revert IndexTooHigh();
        priceTiersValue[index_] = value_;
    }

    function setCombinePrice(uint256 combinePrice_) external override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        combinePrice = combinePrice_;
    }

    function setRunesNFT(address runesNFT_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        runesNFT = runesNFT_;
    }

    function withdraw() external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }

    function withdrawERC20Token(address token_, uint256 amount_) external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token_).safeTransfer(msg.sender, amount_);
    }
}

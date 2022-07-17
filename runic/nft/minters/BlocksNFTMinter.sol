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
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../../lib/AccessControlConstants.sol";
import "../../../nft/interfaces/INFTMintable.sol";
import "../../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../../token/ERC721/extensions/IERC721Burnable.sol";
import "../../../nft/interfaces/INFTAttributes.sol";
import "../lib/BlocksNFTConstants.sol";
import "../lib/CurrenciesNFTConstants.sol";
import "../lib/RunesNFTConstants.sol";
import "../interfaces/ICurrenciesNFT.sol";
import "../interfaces/INFTMaxSupply.sol";
import "../interfaces/INFTPower.sol";
import "../interfaces/IBlocksNFT.sol";
import "../interfaces/IRunicNFT.sol";
import "../interfaces/IBlocksNFTMinter.sol";
import "../interfaces/IOperatorBurn.sol";

/**
 * @notice BlocksNFTMinter
 */
contract BlocksNFTMinter is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable, INFTMaxSupply, IBlocksNFTMinter {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public override(INFTMaxSupply, IBlocksNFTMinter) maxSupply;
    address public blocksNFT;
    address public runesNFT;
    address public currenciesNFT;
    uint256[] public priceTiersSupply;
    uint256[] public priceTiersValue;
    uint256 private _specialMax;
    uint256 private _backgroundMax;
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
    error TicketBalance();              // 0x8e7857c4
    error TicketType();                 // 0x04cf9120

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address blocksNFT_, address runesNFT_, address currenciesNFT_, uint256 mintCount_, uint256 craftCount_) public initializer {
        __BlocksNFTMinter_init(blocksNFT_, runesNFT_, currenciesNFT_, mintCount_, craftCount_);
    }

    function __BlocksNFTMinter_init(address blocksNFT_, address runesNFT_, address currenciesNFT_, uint256 mintCount_, uint256 craftCount_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __BlocksNFTMinter_init_unchained(blocksNFT_, runesNFT_, currenciesNFT_, mintCount_, craftCount_);
    }

    function __BlocksNFTMinter_init_unchained(address blocksNFT_, address runesNFT_, address currenciesNFT_, uint256 mintCount_, uint256 craftCount_) internal onlyInitializing {
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.MINTER_ROLE, msg.sender);
        blocksNFT = blocksNFT_;
        runesNFT = runesNFT_;
        currenciesNFT = currenciesNFT_;
        mintCount = mintCount_;
        craftCount = craftCount_;
        maxSupply = 1000;
        priceTiersSupply = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900];
        priceTiersValue = [550 ether, 600 ether, 650 ether, 700 ether, 750 ether, 800 ether, 850 ether, 900 ether, 950 ether, 1000 ether];
        _specialMax = 6;
        _backgroundMax = 212;
        _pause();
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    receive() external payable {}
    fallback() external payable {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(INFTMaxSupply).interfaceId ||
        interfaceId == type(IBlocksNFTMinter).interfaceId;
    }

    function getPrice() public view returns (uint256 price_) {
        uint256 supply = IERC721Enumerable(blocksNFT).totalSupply();
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
        if(IERC721Enumerable(blocksNFT).totalSupply() >= maxSupply) revert MaxSupply();
        uint256 id_ = INFTMintable(blocksNFT).mint(to_);
        _setAttributes(id_, getRandomRarity());
        INFTPower(blocksNFT).addPower(to_, id_, 1);
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
    function mintSpecific(address to_, RunicNFTLib.RunicAttributes memory attributes_, BlocksNFTLib.BlockAttributes memory blockAttributes_) external override onlyRole(AccessControlConstants.MINTER_ROLE) returns (uint256) {
        uint256 id_ = INFTMintable(blocksNFT).mint(to_);
        IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes_);
        IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes_);
        INFTPower(blocksNFT).addPower(to_, id_, 1);
        mintCount++;
        emit Minted(id_, to_, block.timestamp);
        return id_;
    }

    /**
     * @notice Mint without supply check through operator
     */
    function mintExtra(address to_) external override onlyRole(AccessControlConstants.MINTER_ROLE) returns (uint256) {
        uint256 id_ = INFTMintable(blocksNFT).mint(to_);
        _setAttributes(id_, getRandomRarity());
        INFTPower(blocksNFT).addPower(to_, id_, 1);
        mintCount++;
        emit Minted(id_, to_, block.timestamp);
        return id_;
    }

    /**
     * @notice Mint with ticket
     */
    function mintWithTicket(uint256 ticketId_, uint256 amount_) external whenNotPaused nonReentrant {
        if(IERC1155(currenciesNFT).balanceOf(msg.sender, ticketId_) < amount_) revert TicketBalance();
        CurrenciesNFTLib.CurrencyAttributes memory currency = ICurrenciesNFT(currenciesNFT).getCurrencyAttributes(ticketId_);
        if(currency.categoryId != CurrenciesNFTConstants.CATEGORY_BLOCK_TICKET) revert TicketType();
        ICurrenciesNFT(currenciesNFT).operatorBurn(msg.sender, ticketId_, amount_);
        for(uint256 i; i < amount_; i++) {
            if(IERC721Enumerable(blocksNFT).totalSupply() >= maxSupply) revert MaxSupply();
            uint256 id_ = INFTMintable(blocksNFT).mint(msg.sender);
            // rarity type is stored in value property
            uint32 rarity = getRandomRarityFromRarity(currency.value);
            _setAttributes(id_, rarity);

            // set specific attributes if ticket is specific
            RunicNFTLib.RunicAttributes memory attributes = IRunicNFT(blocksNFT).getRunicAttributes(id_);
            BlocksNFTLib.BlockAttributes memory blockAttributes = IBlocksNFT(blocksNFT).getBlockAttributes(id_);
            if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_PAINTSWAP_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100001;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            } else if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_POPSICLE_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100002;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            } else if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_SCREAM_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100003;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            } else if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_SPIRITSWAP_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100004;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            } else if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_SPOOKYSWAP_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100005;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            } else if(ticketId_ == CurrenciesNFTConstants.ID_BLOCK_LEGENDARY_TOMB_TICKET) {
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
                attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
                attributes.bodyId = 100006;
                attributes.backgroundId = attributes.bodyId;
                IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
                IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
            }
            INFTPower(blocksNFT).addPower(msg.sender, id_, 1);
            mintCount++;
            emit Minted(id_, msg.sender, block.timestamp);
        }
    }

    /**
     * @notice Set attributes
     * @param id_ The token id of nft
     * @param rarity_ The rarity
     */
    function _setAttributes(uint256 id_, uint32 rarity_) internal {
        RunicNFTLib.RunicAttributes memory attributes;
        BlocksNFTLib.BlockAttributes memory blockAttributes;
        uint256 random;
        if(rarity_ == BlocksNFTConstants.RARITY_SPECIAL) {
            blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_SPECIAL;
            attributes.rarityId = BlocksNFTConstants.RARITY_SPECIAL;
            attributes.bodyId = 100000 + uint32(_random(1, _specialMax));
            attributes.backgroundId = attributes.bodyId;
        } else if(rarity_ == BlocksNFTConstants.RARITY_LEGENDARY) {
            blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_ELEMENT;
            attributes.rarityId = BlocksNFTConstants.RARITY_LEGENDARY;
            attributes.elementId = getRandomElementId();
            attributes.backgroundId = 90001 + (attributes.elementId - 1) * 100;
            attributes.bodyId = 90001 + (attributes.elementId - 1) * 100 + uint32(_random(0, 2)); // variation
        } else if(rarity_ == BlocksNFTConstants.RARITY_EPIC) {
            blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_ELEMENT;
            attributes.rarityId = BlocksNFTConstants.RARITY_EPIC;
            attributes.elementId = getRandomElementId();
            attributes.bodyId = 70001 + ((attributes.elementId - 1) * 100) + uint32(_random(0, 2));
            attributes.backgroundId = 70001 + ((attributes.elementId - 1) * 100) + uint32(_random(0, 2));
        } else if(rarity_ == BlocksNFTConstants.RARITY_RARE) {
            attributes.rarityId = BlocksNFTConstants.RARITY_RARE;
            // element or unit
            random = _random(0, 1);
            if(random == 0) {
                // element
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_ELEMENT;
                attributes.elementId = getRandomElementId();
                attributes.bodyId = 50001 + ((attributes.elementId - 1) * 100) + uint32(_random(0, 2));
            } else {
                // unit
                blockAttributes.categoryId = BlocksNFTConstants.CATEGORY_ID_UNIT;
                blockAttributes.typeId = getRandomUnitId();
                attributes.bodyId = 40001 + ((blockAttributes.typeId - 1) * 100) + uint32(_random(0, 2));
            }
            // normal or gradient
            if(_random(1, 10000) < 660) { // 6.6%
                // normal
                attributes.backgroundId = uint32(_random(0, 14));
            } else {
                // gradient
                attributes.backgroundId = 1000 + uint32(_random(1, _backgroundMax));
            }
        } else {
            // common
            // attributes.rarityId = BlocksNFTConstants.RARITY_COMMON;
            blockAttributes.categoryId = uint32(_random(1, 4));
            if(blockAttributes.categoryId == BlocksNFTConstants.CATEGORY_ID_STATS) {
                blockAttributes.typeId = getRandomStatsId();
                attributes.bodyId = 1001 + ((blockAttributes.typeId - 1) * 100) + uint32(_random(0, 14));
            } else if(blockAttributes.categoryId == BlocksNFTConstants.CATEGORY_ID_RESOURCES) {
                blockAttributes.typeId = getRandomResourceId();
                attributes.bodyId = 10001 + ((blockAttributes.typeId - 1) * 100) + uint32(_random(0, 14));
            } else if(blockAttributes.categoryId == BlocksNFTConstants.CATEGORY_ID_UNIT) {
                blockAttributes.typeId = getRandomUnitId();
                attributes.bodyId = 20001 + ((blockAttributes.typeId - 1) * 100) + uint32(_random(0, 14));
            } else {
                attributes.elementId = getRandomElementId();
                attributes.bodyId = 30001 + ((attributes.elementId - 1) * 100) + uint32(_random(0, 14));
            }
            // normal or gradient
            if(_random(1, 10000) < 660) { // 6.6%
                // normal
                attributes.backgroundId = uint32(_random(0, 14));
            } else {
                // gradient
                attributes.backgroundId = 1000 + uint32(_random(1, _backgroundMax));
            }
        }
        IRunicNFT(blocksNFT).setRunicAttributes(id_, attributes);
        IBlocksNFT(blocksNFT).setBlockAttributes(id_, blockAttributes);
    }

    function rerollWithRunes(uint256[] memory tokenIds_, uint256 blockId_) external whenNotPaused nonReentrant {
        _rerollWithRunes(tokenIds_, blockId_);
    }

    /**
     * @notice Reroll using 5 runes to get same or higher rarity block
     * Rarity of runes does not factor into result
     * @param tokenIds_ The token id of the runes
     * @param blockId_ The token id of the block
     */
    function _rerollWithRunes(uint256[] memory tokenIds_, uint256 blockId_) internal {
        if(tokenIds_.length != 5) revert NumRunesRequired(5);
        for(uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if(IERC721(runesNFT).ownerOf(tokenId) != msg.sender) revert NotOwner();
            if(INFTAttributes(runesNFT).getAttribute(RunesNFTConstants.UINT_LOCKED, tokenId) == 1) revert Locked();
            IERC721Burnable(runesNFT).burn(tokenId);
        }
        if(IERC721(blocksNFT).ownerOf(blockId_) != msg.sender) revert NotOwner();
        if(INFTAttributes(blocksNFT).getAttribute(BlocksNFTConstants.UINT_LOCKED, blockId_) == 1) revert Locked();
        RunicNFTLib.RunicAttributes memory attributes = IRunicNFT(blocksNFT).getRunicAttributes(blockId_);

        uint32 rarity = getRandomRerollRarity(attributes.rarityId);
        _setAttributes(blockId_, rarity);
        craftCount++;
        emit Crafted(blockId_, tokenIds_, msg.sender, block.timestamp);
    }

    /**
     * @notice returns random rarity
     */
    function getRandomRarity() internal view returns (uint32) {
        uint256 random = _random(1, 1000);
        if(random <= 10) {
            // special - 1%
            return BlocksNFTConstants.RARITY_SPECIAL;
        } else if(random <= 30) {
            // legendary - 2%
            return BlocksNFTConstants.RARITY_LEGENDARY;
        } else if(random <= 110) {
            // epic - 8%
            return BlocksNFTConstants.RARITY_EPIC;
        } else if(random <= 300) {
            // rare - 19%
            return BlocksNFTConstants.RARITY_RARE;
        }
        // common - 70%
        return BlocksNFTConstants.RARITY_COMMON;
    }

    /**
     * @notice returns random reroll rarity
     */
    function getRandomRerollRarity(uint32 rarity) internal view returns (uint32) {
        uint256 random = _random(1, 1000);
        if(random <= 500) {
            // upgrade rarity
            uint32 newRarity = rarity + 1;
            if(newRarity > BlocksNFTConstants.RARITY_SPECIAL) {
                return rarity;
            }
            if(newRarity > BlocksNFTConstants.RARITY_LEGENDARY) {
                return BlocksNFTConstants.RARITY_SPECIAL;
            }
            return newRarity;
        } else {
            return rarity;
        }
    }

    /**
     * @notice returns random rarity from rarity
     * Can reroll for same or higher rarity but nothing lower
     */
    function getRandomRarityFromRarity(uint32 rarity_) internal view returns (uint32) {
        uint256 random = _random(1, 1000);
        // start with common
        if(rarity_ == BlocksNFTConstants.RARITY_COMMON) {
            if(random <= 10) {
                // special - 1%
                return BlocksNFTConstants.RARITY_SPECIAL;
            } else if(random <= 30) {
                // legendary - 2%
                return BlocksNFTConstants.RARITY_LEGENDARY;
            } else if(random <= 110) {
                // epic - 8%
                return BlocksNFTConstants.RARITY_EPIC;
            } else if(random <= 300) {
                // rare - 19%
                return BlocksNFTConstants.RARITY_RARE;
            }
            // common - 70%
        // start with rare
        } else if(rarity_ == BlocksNFTConstants.RARITY_RARE) {
            if(random <= 10) {
                // special - 1%
                return BlocksNFTConstants.RARITY_SPECIAL;
            } else if(random <= 30) {
                // legendary - 2%
                return BlocksNFTConstants.RARITY_LEGENDARY;
            } else if(random <= 300) {
                // epic - 27%
                return BlocksNFTConstants.RARITY_EPIC;
            } else {
                // rare - 70%
                return BlocksNFTConstants.RARITY_RARE;
            }
        // start with epic
        } else if(rarity_ == BlocksNFTConstants.RARITY_EPIC) {
            if(random <= 30) {
                // legendary - 3%
                return BlocksNFTConstants.RARITY_SPECIAL;
            } else if(random <= 300) {
                // epic - 27%
                return BlocksNFTConstants.RARITY_LEGENDARY;
            } else {
                // rare - 70%
                return BlocksNFTConstants.RARITY_EPIC;
            }
        // start with legendary
        } else if(rarity_ == BlocksNFTConstants.RARITY_LEGENDARY) {
            if(random <= 300) {
                // epic - 30%
                return BlocksNFTConstants.RARITY_SPECIAL;
            } else {
                // rare - 70%
                return BlocksNFTConstants.RARITY_LEGENDARY;
            }
        }
        return BlocksNFTConstants.RARITY_COMMON;
    }

    function getRandomElementId() internal view returns (uint32) {
        return uint32(_random(BlocksNFTConstants.ELEMENT_ID_NEUTRAL, BlocksNFTConstants.ELEMENT_ID_AETHER));
    }

    function getRandomUnitId() internal view returns (uint32) {
        return uint32(_random(BlocksNFTConstants.UNIT_ID_BEAST, BlocksNFTConstants.UNIT_ID_ALIEN));
    }

    function getRandomStatsId() internal view returns (uint32) {
        return uint32(_random(BlocksNFTConstants.STATS_ID_HEALTH, BlocksNFTConstants.STATS_ID_STAMINA));
    }

    function getRandomResourceId() internal view returns (uint32) {
        return uint32(_random(BlocksNFTConstants.RESOURCE_ID_ORE, BlocksNFTConstants.RESOURCE_ID_OIL));
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

    function setSpecialMax(uint256 specialMax_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _specialMax = specialMax_;
    }

    function setBackgroundMax(uint256 backgroundMax_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        _backgroundMax = backgroundMax_;
    }

    function setBlocksNFT(address blocksNFT_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        blocksNFT = blocksNFT_;
    }

    function setRunesNFT(address runesNFT_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        runesNFT = runesNFT_;
    }

    function setCurrenciesNFT(address currenciesNFT_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        currenciesNFT = currenciesNFT_;
    }

    function withdraw() external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }

    function withdrawERC20Token(address token_, uint256 amount_) external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        IERC20Upgradeable(token_).safeTransfer(msg.sender, amount_);
    }
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library BlocksNFTConstants {
    /**
     * Attribute Integer IDs
     */
    uint256 public constant UINT_DISABLE_TEXT = 100; // disable text on nft
    uint256 public constant UINT_LOCKED = 180;       // locked so nft doesn't get used for fodder

    /**
     * Attribute Array IDs
     */

    /**
     * Attribute Address IDs
     */

    /**
     * Attribute String IDs
     */
    uint256 public constant STRING_NAME = 1;
    uint256 public constant STRING_IMAGE_URL = 10;

    /**
     * Address Mapping IDs
     */

    // Rarities
    uint32 public constant RARITY_COMMON = 0; // stats, resources, units, elements with random background
    uint32 public constant RARITY_RARE = 1; // detailed units and elements with random background
    uint32 public constant RARITY_EPIC = 2; // detailed elements with special background
    uint32 public constant RARITY_LEGENDARY = 3; // detailed elements with animated background
    uint32 public constant RARITY_MYTHIC = 4;
    uint32 public constant RARITY_SPECIAL = 10;

    // Categories
    uint32 public constant CATEGORY_ID_NONE = 0;
    uint32 public constant CATEGORY_ID_STATS = 1;
    uint32 public constant CATEGORY_ID_RESOURCES = 2;
    uint32 public constant CATEGORY_ID_UNIT = 3;
    uint32 public constant CATEGORY_ID_ELEMENT = 4;
    uint32 public constant CATEGORY_ID_SPECIAL = 5;

    // Types - Stats
    uint32 public constant STATS_ID_HEALTH = 1;
    uint32 public constant STATS_ID_ATTACK = 2;
    uint32 public constant STATS_ID_MAGIC_ATTACK = 3;
    uint32 public constant STATS_ID_DEFENSE = 4;
    uint32 public constant STATS_ID_MAGIC_DEFENSE = 5;
    uint32 public constant STATS_ID_SPEED = 6;
    uint32 public constant STATS_ID_EXPERIENCE = 7;
    uint32 public constant STATS_ID_STAMINA = 8;

    // Types - Resources
    uint32 public constant RESOURCE_ID_ORE = 1;
    uint32 public constant RESOURCE_ID_HERB = 2;
    uint32 public constant RESOURCE_ID_PARCHMENT = 3;
    uint32 public constant RESOURCE_ID_FLASK = 4;
    uint32 public constant RESOURCE_ID_LEATHER = 5;
    uint32 public constant RESOURCE_ID_JEWEL = 6;
    uint32 public constant RESOURCE_ID_PARTS = 7;
    uint32 public constant RESOURCE_ID_POWDER = 8;
    uint32 public constant RESOURCE_ID_WOOD = 9;
    uint32 public constant RESOURCE_ID_OIL = 10;

    // Types - Units
    uint32 public constant UNIT_ID_BEAST = 1;
    uint32 public constant UNIT_ID_AQUA = 2;
    uint32 public constant UNIT_ID_DINO = 3;
    uint32 public constant UNIT_ID_DRAGON = 4;
    uint32 public constant UNIT_ID_SPIRIT = 5;
    uint32 public constant UNIT_ID_DEMON = 6;
    uint32 public constant UNIT_ID_INSECT = 7;
    uint32 public constant UNIT_ID_MACHINE = 8;
    uint32 public constant UNIT_ID_PLANT = 9;
    uint32 public constant UNIT_ID_PSYCHIC = 10;
    uint32 public constant UNIT_ID_PYRO = 11;
    uint32 public constant UNIT_ID_REPTILE = 12;
    uint32 public constant UNIT_ID_STONE = 13;
    uint32 public constant UNIT_ID_WARRIOR = 14;
    uint32 public constant UNIT_ID_SPELLCASTER = 15;
    uint32 public constant UNIT_ID_AVIAN = 16;
    uint32 public constant UNIT_ID_UNDEAD = 17;
    uint32 public constant UNIT_ID_AMORPHOUS = 18;
    uint32 public constant UNIT_ID_DIVINE = 19;
    uint32 public constant UNIT_ID_ALIEN = 20;

    // Elements
    uint32 public constant ELEMENT_ID_NEUTRAL = 1;
    uint32 public constant ELEMENT_ID_FIRE = 2;
    uint32 public constant ELEMENT_ID_WATER = 3;
    uint32 public constant ELEMENT_ID_NATURE = 4;
    uint32 public constant ELEMENT_ID_EARTH = 5;
    uint32 public constant ELEMENT_ID_WIND = 6;
    uint32 public constant ELEMENT_ID_ICE = 7;
    uint32 public constant ELEMENT_ID_LIGHTNING = 8;
    uint32 public constant ELEMENT_ID_LIGHT = 9;
    uint32 public constant ELEMENT_ID_DARK = 10;
    uint32 public constant ELEMENT_ID_METAL = 11;
    uint32 public constant ELEMENT_ID_NETHER = 12;
    uint32 public constant ELEMENT_ID_AETHER = 13;

    // Special
    uint32 public constant SPECIAL_ID_PAINTSWAP = 1;
    uint32 public constant SPECIAL_ID_POPSICLE = 2;
    uint32 public constant SPECIAL_ID_SCREAM = 3;
    uint32 public constant SPECIAL_ID_SPIRITSWAP = 4;
    uint32 public constant SPECIAL_ID_SPOOKYSWAP = 5;
    uint32 public constant SPECIAL_ID_TOMB = 6;
}
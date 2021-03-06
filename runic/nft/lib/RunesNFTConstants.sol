// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library RunesNFTConstants {
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
    uint32 public constant RARITY_COMMON = 0; // basic logo
    uint32 public constant RARITY_RARE = 1; // element logo
    uint32 public constant RARITY_EPIC = 2; // element logo with background
    uint32 public constant RARITY_LEGENDARY = 3; // element logo with animated background
    uint32 public constant RARITY_MYTHIC = 4;

    // Backgrounds
    uint32 public constant BACKGROUND_ID_NONE = 0;
    uint32 public constant BACKGROUND_ID_RED = 1;
    uint32 public constant BACKGROUND_ID_ORANGE = 2;
    uint32 public constant BACKGROUND_ID_YELLOW = 3;
    uint32 public constant BACKGROUND_ID_LIGHT_GREEN = 4;
    uint32 public constant BACKGROUND_ID_GREEN = 5;
    uint32 public constant BACKGROUND_ID_BLUE = 6;
    uint32 public constant BACKGROUND_ID_INDIGO = 7;
    uint32 public constant BACKGROUND_ID_VIOLET = 8;
    uint32 public constant BACKGROUND_ID_PINK = 9;
    uint32 public constant BACKGROUND_ID_WHITE = 10;
    uint32 public constant BACKGROUND_ID_GRAY = 11;
    uint32 public constant BACKGROUND_ID_BROWN = 12;
    uint32 public constant BACKGROUND_ID_BLACK = 13;
    uint32 public constant BACKGROUND_ID_RAINBOW = 14;

    // Elemental Backgrounds
    uint32 public constant BACKGROUND_ID_NEUTRAL_1 = 3000;
    uint32 public constant BACKGROUND_ID_NEUTRAL_2 = 3001;
    uint32 public constant BACKGROUND_ID_FIRE_1 = 3010;
    uint32 public constant BACKGROUND_ID_FIRE_2 = 3011;
    uint32 public constant BACKGROUND_ID_WATER_1 = 3020;
    uint32 public constant BACKGROUND_ID_WATER_2 = 3021;
    uint32 public constant BACKGROUND_ID_NATURE_1 = 3030;
    uint32 public constant BACKGROUND_ID_NATURE_2 = 3031;
    uint32 public constant BACKGROUND_ID_EARTH_1 = 3040;
    uint32 public constant BACKGROUND_ID_EARTH_2 = 3041;
    uint32 public constant BACKGROUND_ID_WIND_1 = 3050;
    uint32 public constant BACKGROUND_ID_WIND_2 = 3051;
    uint32 public constant BACKGROUND_ID_ICE_1 = 3060;
    uint32 public constant BACKGROUND_ID_ICE_2 = 3061;
    uint32 public constant BACKGROUND_ID_LIGHTNING_1 = 3070;
    uint32 public constant BACKGROUND_ID_LIGHTNING_2 = 3071;
    uint32 public constant BACKGROUND_ID_LIGHT_1 = 3080;
    uint32 public constant BACKGROUND_ID_LIGHT_2 = 3081;
    uint32 public constant BACKGROUND_ID_DARK_1 = 3090;
    uint32 public constant BACKGROUND_ID_DARK_2 = 3091;
    uint32 public constant BACKGROUND_ID_METAL_1 = 3100;
    uint32 public constant BACKGROUND_ID_METAL_2 = 3101;
    uint32 public constant BACKGROUND_ID_NETHER_1 = 3110;
    uint32 public constant BACKGROUND_ID_NETHER_2 = 3111;
    uint32 public constant BACKGROUND_ID_AETHER_1 = 3120;
    uint32 public constant BACKGROUND_ID_AETHER_2 = 3121;

    // Legendary Backgrounds
    uint32 public constant BACKGROUND_ID_LEGENDARY_NEUTRAL = 4000;
    uint32 public constant BACKGROUND_ID_LEGENDARY_FIRE = 4010;
    uint32 public constant BACKGROUND_ID_LEGENDARY_WATER = 4020;
    uint32 public constant BACKGROUND_ID_LEGENDARY_NATURE = 4030;
    uint32 public constant BACKGROUND_ID_LEGENDARY_EARTH = 4040;
    uint32 public constant BACKGROUND_ID_LEGENDARY_WIND = 4050;
    uint32 public constant BACKGROUND_ID_LEGENDARY_ICE = 4060;
    uint32 public constant BACKGROUND_ID_LEGENDARY_LIGHTNING = 4070;
    uint32 public constant BACKGROUND_ID_LEGENDARY_LIGHT = 4080;
    uint32 public constant BACKGROUND_ID_LEGENDARY_DARK = 4090;
    uint32 public constant BACKGROUND_ID_LEGENDARY_METAL = 4100;
    uint32 public constant BACKGROUND_ID_LEGENDARY_NETHER = 4110;
    uint32 public constant BACKGROUND_ID_LEGENDARY_AETHER = 4120;

    // Runes
    uint32 public constant RUNE_ID_RED = 1;
    uint32 public constant RUNE_ID_RED_2 = 2;
    uint32 public constant RUNE_ID_ORANGE = 3;
    uint32 public constant RUNE_ID_ORANGE_2 = 4;
    uint32 public constant RUNE_ID_YELLOW = 5;
    uint32 public constant RUNE_ID_YELLOW_2 = 6;
    uint32 public constant RUNE_ID_LIME_GREEN = 7;
    uint32 public constant RUNE_ID_LIME_GREEN_2 = 8;
    uint32 public constant RUNE_ID_GREEN = 9;
    uint32 public constant RUNE_ID_GREEN_2 = 10;
    uint32 public constant RUNE_ID_BLUE = 11;
    uint32 public constant RUNE_ID_BLUE_2 = 12;
    uint32 public constant RUNE_ID_INDIGO = 13;
    uint32 public constant RUNE_ID_INDIGO_2 = 14;
    uint32 public constant RUNE_ID_VIOLET = 15;
    uint32 public constant RUNE_ID_VIOLET_2 = 16;
    uint32 public constant RUNE_ID_PINK = 17;
    uint32 public constant RUNE_ID_PINK_2 = 18;
    uint32 public constant RUNE_ID_WHITE = 19;
    uint32 public constant RUNE_ID_WHITE_2 = 20;
    uint32 public constant RUNE_ID_GRAY = 21;
    uint32 public constant RUNE_ID_GRAY_2 = 22;
    uint32 public constant RUNE_ID_BROWN = 23;
    uint32 public constant RUNE_ID_BROWN_2 = 24;
    uint32 public constant RUNE_ID_BLACK = 25;
    uint32 public constant RUNE_ID_BLACK_2 = 26;
    uint32 public constant RUNE_ID_RAINBOW = 27;
    uint32 public constant RUNE_ID_RAINBOW_2 = 28;

    // Rare Elemental Runes
    uint32 public constant RUNE_ID_NEUTRAL_RED = 1001;
    uint32 public constant RUNE_ID_NEUTRAL_RED_2 = 1002;
    uint32 public constant RUNE_ID_NEUTRAL_ORANGE = 1003;
    uint32 public constant RUNE_ID_NEUTRAL_ORANGE_2 = 1004;
    uint32 public constant RUNE_ID_NEUTRAL_YELLOW = 1005;
    uint32 public constant RUNE_ID_NEUTRAL_YELLOW_2 = 1006;
    uint32 public constant RUNE_ID_NEUTRAL_LIGHT_GREEN = 1007;
    uint32 public constant RUNE_ID_NEUTRAL_LIGHT_GREEN_2 = 1008;
    uint32 public constant RUNE_ID_NEUTRAL_GREEN = 1009;
    uint32 public constant RUNE_ID_NEUTRAL_GREEN_2 = 1010;
    uint32 public constant RUNE_ID_NEUTRAL_BLUE = 1011;
    uint32 public constant RUNE_ID_NEUTRAL_BLUE_2 = 1012;
    uint32 public constant RUNE_ID_NEUTRAL_INDIGO = 1013;
    uint32 public constant RUNE_ID_NEUTRAL_INDIGO_2 = 1014;
    uint32 public constant RUNE_ID_NEUTRAL_VIOLET = 1015;
    uint32 public constant RUNE_ID_NEUTRAL_VIOLET_2 = 1016;
    uint32 public constant RUNE_ID_NEUTRAL_PINK = 1017;
    uint32 public constant RUNE_ID_NEUTRAL_PINK_2 = 1018;
    uint32 public constant RUNE_ID_NEUTRAL_WHITE = 1019;
    uint32 public constant RUNE_ID_NEUTRAL_WHITE_2 = 1020;
    uint32 public constant RUNE_ID_NEUTRAL_GRAY = 1021;
    uint32 public constant RUNE_ID_NEUTRAL_GRAY_2 = 1022;
    uint32 public constant RUNE_ID_NEUTRAL_BROWN = 1023;
    uint32 public constant RUNE_ID_NEUTRAL_BROWN_2 = 1024;
    uint32 public constant RUNE_ID_NEUTRAL_BLACK = 1025;
    uint32 public constant RUNE_ID_NEUTRAL_BLACK_2 = 1026;
    uint32 public constant RUNE_ID_NEUTRAL_RAINBOW = 1027;
    uint32 public constant RUNE_ID_NEUTRAL_RAINBOW_2 = 1028;

    uint32 public constant RUNE_ID_FIRE_RED = 1101;
    uint32 public constant RUNE_ID_FIRE_RED_2 = 1102;
    uint32 public constant RUNE_ID_FIRE_ORANGE = 1103;
    uint32 public constant RUNE_ID_FIRE_ORANGE_2 = 1104;
    uint32 public constant RUNE_ID_FIRE_YELLOW = 1105;
    uint32 public constant RUNE_ID_FIRE_YELLOW_2 = 1106;
    uint32 public constant RUNE_ID_FIRE_LIGHT_GREEN = 1107;
    uint32 public constant RUNE_ID_FIRE_LIGHT_GREEN_2 = 1108;
    uint32 public constant RUNE_ID_FIRE_GREEN = 1109;
    uint32 public constant RUNE_ID_FIRE_GREEN_2 = 1110;
    uint32 public constant RUNE_ID_FIRE_BLUE = 1111;
    uint32 public constant RUNE_ID_FIRE_BLUE_2 = 1112;
    uint32 public constant RUNE_ID_FIRE_INDIGO = 1113;
    uint32 public constant RUNE_ID_FIRE_INDIGO_2 = 1114;
    uint32 public constant RUNE_ID_FIRE_VIOLET = 1115;
    uint32 public constant RUNE_ID_FIRE_VIOLET_2 = 1116;
    uint32 public constant RUNE_ID_FIRE_PINK = 1117;
    uint32 public constant RUNE_ID_FIRE_PINK_2 = 1118;
    uint32 public constant RUNE_ID_FIRE_WHITE = 1119;
    uint32 public constant RUNE_ID_FIRE_WHITE_2 = 1120;
    uint32 public constant RUNE_ID_FIRE_GRAY = 1121;
    uint32 public constant RUNE_ID_FIRE_GRAY_2 = 1122;
    uint32 public constant RUNE_ID_FIRE_BROWN = 1123;
    uint32 public constant RUNE_ID_FIRE_BROWN_2 = 1124;
    uint32 public constant RUNE_ID_FIRE_BLACK = 1125;
    uint32 public constant RUNE_ID_FIRE_BLACK_2 = 1126;
    uint32 public constant RUNE_ID_FIRE_RAINBOW = 1127;
    uint32 public constant RUNE_ID_FIRE_RAINBOW_2 = 1128;

    uint32 public constant RUNE_ID_WATER_RED = 1201;
    uint32 public constant RUNE_ID_WATER_RED_2 = 1202;
    uint32 public constant RUNE_ID_WATER_ORANGE = 1203;
    uint32 public constant RUNE_ID_WATER_ORANGE_2 = 1204;
    uint32 public constant RUNE_ID_WATER_YELLOW = 1205;
    uint32 public constant RUNE_ID_WATER_YELLOW_2 = 1206;
    uint32 public constant RUNE_ID_WATER_LIGHT_GREEN = 1207;
    uint32 public constant RUNE_ID_WATER_LIGHT_GREEN_2 = 1208;
    uint32 public constant RUNE_ID_WATER_GREEN = 1209;
    uint32 public constant RUNE_ID_WATER_GREEN_2 = 1210;
    uint32 public constant RUNE_ID_WATER_BLUE = 1211;
    uint32 public constant RUNE_ID_WATER_BLUE_2 = 1212;
    uint32 public constant RUNE_ID_WATER_INDIGO = 1213;
    uint32 public constant RUNE_ID_WATER_INDIGO_2 = 1214;
    uint32 public constant RUNE_ID_WATER_VIOLET = 1215;
    uint32 public constant RUNE_ID_WATER_VIOLET_2 = 1216;
    uint32 public constant RUNE_ID_WATER_PINK = 1217;
    uint32 public constant RUNE_ID_WATER_PINK_2 = 1218;
    uint32 public constant RUNE_ID_WATER_WHITE = 1219;
    uint32 public constant RUNE_ID_WATER_WHITE_2 = 1220;
    uint32 public constant RUNE_ID_WATER_GRAY = 1221;
    uint32 public constant RUNE_ID_WATER_GRAY_2 = 1222;
    uint32 public constant RUNE_ID_WATER_BROWN = 1223;
    uint32 public constant RUNE_ID_WATER_BROWN_2 = 1224;
    uint32 public constant RUNE_ID_WATER_BLACK = 1225;
    uint32 public constant RUNE_ID_WATER_BLACK_2 = 1226;
    uint32 public constant RUNE_ID_WATER_RAINBOW = 1227;
    uint32 public constant RUNE_ID_WATER_RAINBOW_2 = 1228;

    uint32 public constant RUNE_ID_NATURE_RED = 1301;
    uint32 public constant RUNE_ID_NATURE_RED_2 = 1302;
    uint32 public constant RUNE_ID_NATURE_ORANGE = 1303;
    uint32 public constant RUNE_ID_NATURE_ORANGE_2 = 1304;
    uint32 public constant RUNE_ID_NATURE_YELLOW = 1305;
    uint32 public constant RUNE_ID_NATURE_YELLOW_2 = 1306;
    uint32 public constant RUNE_ID_NATURE_LIGHT_GREEN = 1307;
    uint32 public constant RUNE_ID_NATURE_LIGHT_GREEN_2 = 1308;
    uint32 public constant RUNE_ID_NATURE_GREEN = 1309;
    uint32 public constant RUNE_ID_NATURE_GREEN_2 = 1310;
    uint32 public constant RUNE_ID_NATURE_BLUE = 1311;
    uint32 public constant RUNE_ID_NATURE_BLUE_2 = 1312;
    uint32 public constant RUNE_ID_NATURE_INDIGO = 1313;
    uint32 public constant RUNE_ID_NATURE_INDIGO_2 = 1314;
    uint32 public constant RUNE_ID_NATURE_VIOLET = 1315;
    uint32 public constant RUNE_ID_NATURE_VIOLET_2 = 1316;
    uint32 public constant RUNE_ID_NATURE_PINK = 1317;
    uint32 public constant RUNE_ID_NATURE_PINK_2 = 1318;
    uint32 public constant RUNE_ID_NATURE_WHITE = 1319;
    uint32 public constant RUNE_ID_NATURE_WHITE_2 = 1320;
    uint32 public constant RUNE_ID_NATURE_GRAY = 1321;
    uint32 public constant RUNE_ID_NATURE_GRAY_2 = 1322;
    uint32 public constant RUNE_ID_NATURE_BROWN = 1323;
    uint32 public constant RUNE_ID_NATURE_BROWN_2 = 1324;
    uint32 public constant RUNE_ID_NATURE_BLACK = 1325;
    uint32 public constant RUNE_ID_NATURE_BLACK_2 = 1326;
    uint32 public constant RUNE_ID_NATURE_RAINBOW = 1327;
    uint32 public constant RUNE_ID_NATURE_RAINBOW_2 = 1328;

    uint32 public constant RUNE_ID_EARTH_RED = 1401;
    uint32 public constant RUNE_ID_EARTH_RED_2 = 1402;
    uint32 public constant RUNE_ID_EARTH_ORANGE = 1403;
    uint32 public constant RUNE_ID_EARTH_ORANGE_2 = 1404;
    uint32 public constant RUNE_ID_EARTH_YELLOW = 1405;
    uint32 public constant RUNE_ID_EARTH_YELLOW_2 = 1406;
    uint32 public constant RUNE_ID_EARTH_LIGHT_GREEN = 1407;
    uint32 public constant RUNE_ID_EARTH_LIGHT_GREEN_2 = 1408;
    uint32 public constant RUNE_ID_EARTH_GREEN = 1409;
    uint32 public constant RUNE_ID_EARTH_GREEN_2 = 1410;
    uint32 public constant RUNE_ID_EARTH_BLUE = 1411;
    uint32 public constant RUNE_ID_EARTH_BLUE_2 = 1412;
    uint32 public constant RUNE_ID_EARTH_INDIGO = 1413;
    uint32 public constant RUNE_ID_EARTH_INDIGO_2 = 1414;
    uint32 public constant RUNE_ID_EARTH_VIOLET = 1415;
    uint32 public constant RUNE_ID_EARTH_VIOLET_2 = 1416;
    uint32 public constant RUNE_ID_EARTH_PINK = 1417;
    uint32 public constant RUNE_ID_EARTH_PINK_2 = 1418;
    uint32 public constant RUNE_ID_EARTH_WHITE = 1419;
    uint32 public constant RUNE_ID_EARTH_WHITE_2 = 1420;
    uint32 public constant RUNE_ID_EARTH_GRAY = 1421;
    uint32 public constant RUNE_ID_EARTH_GRAY_2 = 1422;
    uint32 public constant RUNE_ID_EARTH_BROWN = 1423;
    uint32 public constant RUNE_ID_EARTH_BROWN_2 = 1424;
    uint32 public constant RUNE_ID_EARTH_BLACK = 1425;
    uint32 public constant RUNE_ID_EARTH_BLACK_2 = 1426;
    uint32 public constant RUNE_ID_EARTH_RAINBOW = 1427;
    uint32 public constant RUNE_ID_EARTH_RAINBOW_2 = 1428;

    uint32 public constant RUNE_ID_WIND_RED = 1501;
    uint32 public constant RUNE_ID_WIND_RED_2 = 1502;
    uint32 public constant RUNE_ID_WIND_ORANGE = 1503;
    uint32 public constant RUNE_ID_WIND_ORANGE_2 = 1504;
    uint32 public constant RUNE_ID_WIND_YELLOW = 1505;
    uint32 public constant RUNE_ID_WIND_YELLOW_2 = 1506;
    uint32 public constant RUNE_ID_WIND_LIGHT_GREEN = 1507;
    uint32 public constant RUNE_ID_WIND_LIGHT_GREEN_2 = 1508;
    uint32 public constant RUNE_ID_WIND_GREEN = 1509;
    uint32 public constant RUNE_ID_WIND_GREEN_2 = 1510;
    uint32 public constant RUNE_ID_WIND_BLUE = 1511;
    uint32 public constant RUNE_ID_WIND_BLUE_2 = 1512;
    uint32 public constant RUNE_ID_WIND_INDIGO = 1513;
    uint32 public constant RUNE_ID_WIND_INDIGO_2 = 1514;
    uint32 public constant RUNE_ID_WIND_VIOLET = 1515;
    uint32 public constant RUNE_ID_WIND_VIOLET_2 = 1516;
    uint32 public constant RUNE_ID_WIND_PINK = 1517;
    uint32 public constant RUNE_ID_WIND_PINK_2 = 1518;
    uint32 public constant RUNE_ID_WIND_WHITE = 1519;
    uint32 public constant RUNE_ID_WIND_WHITE_2 = 1520;
    uint32 public constant RUNE_ID_WIND_GRAY = 1521;
    uint32 public constant RUNE_ID_WIND_GRAY_2 = 1522;
    uint32 public constant RUNE_ID_WIND_BROWN = 1523;
    uint32 public constant RUNE_ID_WIND_BROWN_2 = 1524;
    uint32 public constant RUNE_ID_WIND_BLACK = 1525;
    uint32 public constant RUNE_ID_WIND_BLACK_2 = 1526;
    uint32 public constant RUNE_ID_WIND_RAINBOW = 1527;
    uint32 public constant RUNE_ID_WIND_RAINBOW_2 = 1528;

    uint32 public constant RUNE_ID_ICE_RED = 1601;
    uint32 public constant RUNE_ID_ICE_RED_2 = 1602;
    uint32 public constant RUNE_ID_ICE_ORANGE = 1603;
    uint32 public constant RUNE_ID_ICE_ORANGE_2 = 1604;
    uint32 public constant RUNE_ID_ICE_YELLOW = 1605;
    uint32 public constant RUNE_ID_ICE_YELLOW_2 = 1606;
    uint32 public constant RUNE_ID_ICE_LIGHT_GREEN = 1607;
    uint32 public constant RUNE_ID_ICE_LIGHT_GREEN_2 = 1608;
    uint32 public constant RUNE_ID_ICE_GREEN = 1609;
    uint32 public constant RUNE_ID_ICE_GREEN_2 = 1610;
    uint32 public constant RUNE_ID_ICE_BLUE = 1611;
    uint32 public constant RUNE_ID_ICE_BLUE_2 = 1612;
    uint32 public constant RUNE_ID_ICE_INDIGO = 1613;
    uint32 public constant RUNE_ID_ICE_INDIGO_2 = 1614;
    uint32 public constant RUNE_ID_ICE_VIOLET = 1615;
    uint32 public constant RUNE_ID_ICE_VIOLET_2 = 1616;
    uint32 public constant RUNE_ID_ICE_PINK = 1617;
    uint32 public constant RUNE_ID_ICE_PINK_2 = 1618;
    uint32 public constant RUNE_ID_ICE_WHITE = 1619;
    uint32 public constant RUNE_ID_ICE_WHITE_2 = 1620;
    uint32 public constant RUNE_ID_ICE_GRAY = 1621;
    uint32 public constant RUNE_ID_ICE_GRAY_2 = 1622;
    uint32 public constant RUNE_ID_ICE_BROWN = 1623;
    uint32 public constant RUNE_ID_ICE_BROWN_2 = 1624;
    uint32 public constant RUNE_ID_ICE_BLACK = 1625;
    uint32 public constant RUNE_ID_ICE_BLACK_2 = 1626;
    uint32 public constant RUNE_ID_ICE_RAINBOW = 1627;
    uint32 public constant RUNE_ID_ICE_RAINBOW_2 = 1628;

    uint32 public constant RUNE_ID_LIGHTNING_RED = 1701;
    uint32 public constant RUNE_ID_LIGHTNING_RED_2 = 1702;
    uint32 public constant RUNE_ID_LIGHTNING_ORANGE = 1703;
    uint32 public constant RUNE_ID_LIGHTNING_ORANGE_2 = 1704;
    uint32 public constant RUNE_ID_LIGHTNING_YELLOW = 1705;
    uint32 public constant RUNE_ID_LIGHTNING_YELLOW_2 = 1706;
    uint32 public constant RUNE_ID_LIGHTNING_LIGHT_GREEN = 1707;
    uint32 public constant RUNE_ID_LIGHTNING_LIGHT_GREEN_2 = 1708;
    uint32 public constant RUNE_ID_LIGHTNING_GREEN = 1709;
    uint32 public constant RUNE_ID_LIGHTNING_GREEN_2 = 1710;
    uint32 public constant RUNE_ID_LIGHTNING_BLUE = 1711;
    uint32 public constant RUNE_ID_LIGHTNING_BLUE_2 = 1712;
    uint32 public constant RUNE_ID_LIGHTNING_INDIGO = 1713;
    uint32 public constant RUNE_ID_LIGHTNING_INDIGO_2 = 1714;
    uint32 public constant RUNE_ID_LIGHTNING_VIOLET = 1715;
    uint32 public constant RUNE_ID_LIGHTNING_VIOLET_2 = 1716;
    uint32 public constant RUNE_ID_LIGHTNING_PINK = 1717;
    uint32 public constant RUNE_ID_LIGHTNING_PINK_2 = 1718;
    uint32 public constant RUNE_ID_LIGHTNING_WHITE = 1719;
    uint32 public constant RUNE_ID_LIGHTNING_WHITE_2 = 1720;
    uint32 public constant RUNE_ID_LIGHTNING_GRAY = 1721;
    uint32 public constant RUNE_ID_LIGHTNING_GRAY_2 = 1722;
    uint32 public constant RUNE_ID_LIGHTNING_BROWN = 1723;
    uint32 public constant RUNE_ID_LIGHTNING_BROWN_2 = 1724;
    uint32 public constant RUNE_ID_LIGHTNING_BLACK = 1725;
    uint32 public constant RUNE_ID_LIGHTNING_BLACK_2 = 1726;
    uint32 public constant RUNE_ID_LIGHTNING_RAINBOW = 1727;
    uint32 public constant RUNE_ID_LIGHTNING_RAINBOW_2 = 1728;

    uint32 public constant RUNE_ID_LIGHT_RED = 1801;
    uint32 public constant RUNE_ID_LIGHT_RED_2 = 1802;
    uint32 public constant RUNE_ID_LIGHT_ORANGE = 1803;
    uint32 public constant RUNE_ID_LIGHT_ORANGE_2 = 1804;
    uint32 public constant RUNE_ID_LIGHT_YELLOW = 1805;
    uint32 public constant RUNE_ID_LIGHT_YELLOW_2 = 1806;
    uint32 public constant RUNE_ID_LIGHT_LIME_GREEN = 1807;
    uint32 public constant RUNE_ID_LIGHT_LIME_GREEN_2 = 1808;
    uint32 public constant RUNE_ID_LIGHT_GREEN = 1809;
    uint32 public constant RUNE_ID_LIGHT_GREEN_2 = 1810;
    uint32 public constant RUNE_ID_LIGHT_BLUE = 1811;
    uint32 public constant RUNE_ID_LIGHT_BLUE_2 = 1812;
    uint32 public constant RUNE_ID_LIGHT_INDIGO = 1813;
    uint32 public constant RUNE_ID_LIGHT_INDIGO_2 = 1814;
    uint32 public constant RUNE_ID_LIGHT_VIOLET = 1815;
    uint32 public constant RUNE_ID_LIGHT_VIOLET_2 = 1816;
    uint32 public constant RUNE_ID_LIGHT_PINK = 1817;
    uint32 public constant RUNE_ID_LIGHT_PINK_2 = 1818;
    uint32 public constant RUNE_ID_LIGHT_WHITE = 1819;
    uint32 public constant RUNE_ID_LIGHT_WHITE_2 = 1820;
    uint32 public constant RUNE_ID_LIGHT_GRAY = 1821;
    uint32 public constant RUNE_ID_LIGHT_GRAY_2 = 1822;
    uint32 public constant RUNE_ID_LIGHT_BROWN = 1823;
    uint32 public constant RUNE_ID_LIGHT_BROWN_2 = 1824;
    uint32 public constant RUNE_ID_LIGHT_BLACK = 1825;
    uint32 public constant RUNE_ID_LIGHT_BLACK_2 = 1826;
    uint32 public constant RUNE_ID_LIGHT_RAINBOW = 1827;
    uint32 public constant RUNE_ID_LIGHT_RAINBOW_2 = 1828;

    uint32 public constant RUNE_ID_DARK_RED = 1901;
    uint32 public constant RUNE_ID_DARK_RED_2 = 1902;
    uint32 public constant RUNE_ID_DARK_ORANGE = 1903;
    uint32 public constant RUNE_ID_DARK_ORANGE_2 = 1904;
    uint32 public constant RUNE_ID_DARK_YELLOW = 1905;
    uint32 public constant RUNE_ID_DARK_YELLOW_2 = 1906;
    uint32 public constant RUNE_ID_DARK_LIGHT_GREEN = 1907;
    uint32 public constant RUNE_ID_DARK_LIGHT_GREEN_2 = 1908;
    uint32 public constant RUNE_ID_DARK_GREEN = 1909;
    uint32 public constant RUNE_ID_DARK_GREEN_2 = 1910;
    uint32 public constant RUNE_ID_DARK_BLUE = 1911;
    uint32 public constant RUNE_ID_DARK_BLUE_2 = 1912;
    uint32 public constant RUNE_ID_DARK_INDIGO = 1913;
    uint32 public constant RUNE_ID_DARK_INDIGO_2 = 1914;
    uint32 public constant RUNE_ID_DARK_VIOLET = 1915;
    uint32 public constant RUNE_ID_DARK_VIOLET_2 = 1916;
    uint32 public constant RUNE_ID_DARK_PINK = 1917;
    uint32 public constant RUNE_ID_DARK_PINK_2 = 1918;
    uint32 public constant RUNE_ID_DARK_WHITE = 1919;
    uint32 public constant RUNE_ID_DARK_WHITE_2 = 1920;
    uint32 public constant RUNE_ID_DARK_GRAY = 1921;
    uint32 public constant RUNE_ID_DARK_GRAY_2 = 1922;
    uint32 public constant RUNE_ID_DARK_BROWN = 1923;
    uint32 public constant RUNE_ID_DARK_BROWN_2 = 1924;
    uint32 public constant RUNE_ID_DARK_BLACK = 1925;
    uint32 public constant RUNE_ID_DARK_BLACK_2 = 1926;
    uint32 public constant RUNE_ID_DARK_RAINBOW = 1927;
    uint32 public constant RUNE_ID_DARK_RAINBOW_2 = 1928;

    uint32 public constant RUNE_ID_METAL_RED = 2001;
    uint32 public constant RUNE_ID_METAL_RED_2 = 2002;
    uint32 public constant RUNE_ID_METAL_ORANGE = 2003;
    uint32 public constant RUNE_ID_METAL_ORANGE_2 = 2004;
    uint32 public constant RUNE_ID_METAL_YELLOW = 2005;
    uint32 public constant RUNE_ID_METAL_YELLOW_2 = 2006;
    uint32 public constant RUNE_ID_METAL_LIGHT_GREEN = 2007;
    uint32 public constant RUNE_ID_METAL_LIGHT_GREEN_2 = 2008;
    uint32 public constant RUNE_ID_METAL_GREEN = 2009;
    uint32 public constant RUNE_ID_METAL_GREEN_2 = 2010;
    uint32 public constant RUNE_ID_METAL_BLUE = 2011;
    uint32 public constant RUNE_ID_METAL_BLUE_2 = 2012;
    uint32 public constant RUNE_ID_METAL_INDIGO = 2013;
    uint32 public constant RUNE_ID_METAL_INDIGO_2 = 2014;
    uint32 public constant RUNE_ID_METAL_VIOLET = 2015;
    uint32 public constant RUNE_ID_METAL_VIOLET_2 = 2016;
    uint32 public constant RUNE_ID_METAL_PINK = 2017;
    uint32 public constant RUNE_ID_METAL_PINK_2 = 2018;
    uint32 public constant RUNE_ID_METAL_WHITE = 2019;
    uint32 public constant RUNE_ID_METAL_WHITE_2 = 2020;
    uint32 public constant RUNE_ID_METAL_GRAY = 2021;
    uint32 public constant RUNE_ID_METAL_GRAY_2 = 2022;
    uint32 public constant RUNE_ID_METAL_BROWN = 2023;
    uint32 public constant RUNE_ID_METAL_BROWN_2 = 2024;
    uint32 public constant RUNE_ID_METAL_BLACK = 2025;
    uint32 public constant RUNE_ID_METAL_BLACK_2 = 2026;
    uint32 public constant RUNE_ID_METAL_RAINBOW = 2027;
    uint32 public constant RUNE_ID_METAL_RAINBOW_2 = 2028;

    uint32 public constant RUNE_ID_NETHER_RED = 2101;
    uint32 public constant RUNE_ID_NETHER_RED_2 = 2102;
    uint32 public constant RUNE_ID_NETHER_ORANGE = 2103;
    uint32 public constant RUNE_ID_NETHER_ORANGE_2 = 2104;
    uint32 public constant RUNE_ID_NETHER_YELLOW = 2105;
    uint32 public constant RUNE_ID_NETHER_YELLOW_2 = 2106;
    uint32 public constant RUNE_ID_NETHER_LIGHT_GREEN = 2107;
    uint32 public constant RUNE_ID_NETHER_LIGHT_GREEN_2 = 2108;
    uint32 public constant RUNE_ID_NETHER_GREEN = 2109;
    uint32 public constant RUNE_ID_NETHER_GREEN_2 = 2110;
    uint32 public constant RUNE_ID_NETHER_BLUE = 2111;
    uint32 public constant RUNE_ID_NETHER_BLUE_2 = 2112;
    uint32 public constant RUNE_ID_NETHER_INDIGO = 2113;
    uint32 public constant RUNE_ID_NETHER_INDIGO_2 = 2114;
    uint32 public constant RUNE_ID_NETHER_VIOLET = 2115;
    uint32 public constant RUNE_ID_NETHER_VIOLET_2 = 2116;
    uint32 public constant RUNE_ID_NETHER_PINK = 2117;
    uint32 public constant RUNE_ID_NETHER_PINK_2 = 2118;
    uint32 public constant RUNE_ID_NETHER_WHITE = 2119;
    uint32 public constant RUNE_ID_NETHER_WHITE_2 = 2120;
    uint32 public constant RUNE_ID_NETHER_GRAY = 2121;
    uint32 public constant RUNE_ID_NETHER_GRAY_2 = 2122;
    uint32 public constant RUNE_ID_NETHER_BROWN = 2123;
    uint32 public constant RUNE_ID_NETHER_BROWN_2 = 2124;
    uint32 public constant RUNE_ID_NETHER_BLACK = 2125;
    uint32 public constant RUNE_ID_NETHER_BLACK_2 = 2126;
    uint32 public constant RUNE_ID_NETHER_RAINBOW = 2127;
    uint32 public constant RUNE_ID_NETHER_RAINBOW_2 = 2128;

    uint32 public constant RUNE_ID_AETHER_RED = 2201;
    uint32 public constant RUNE_ID_AETHER_RED_2 = 2202;
    uint32 public constant RUNE_ID_AETHER_ORANGE = 2203;
    uint32 public constant RUNE_ID_AETHER_ORANGE_2 = 2204;
    uint32 public constant RUNE_ID_AETHER_YELLOW = 2205;
    uint32 public constant RUNE_ID_AETHER_YELLOW_2 = 2206;
    uint32 public constant RUNE_ID_AETHER_LIGHT_GREEN = 2207;
    uint32 public constant RUNE_ID_AETHER_LIGHT_GREEN_2 = 2208;
    uint32 public constant RUNE_ID_AETHER_GREEN = 2209;
    uint32 public constant RUNE_ID_AETHER_GREEN_2 = 2210;
    uint32 public constant RUNE_ID_AETHER_BLUE = 2211;
    uint32 public constant RUNE_ID_AETHER_BLUE_2 = 2212;
    uint32 public constant RUNE_ID_AETHER_INDIGO = 2213;
    uint32 public constant RUNE_ID_AETHER_INDIGO_2 = 2214;
    uint32 public constant RUNE_ID_AETHER_VIOLET = 2215;
    uint32 public constant RUNE_ID_AETHER_VIOLET_2 = 2216;
    uint32 public constant RUNE_ID_AETHER_PINK = 2217;
    uint32 public constant RUNE_ID_AETHER_PINK_2 = 2218;
    uint32 public constant RUNE_ID_AETHER_WHITE = 2219;
    uint32 public constant RUNE_ID_AETHER_WHITE_2 = 2220;
    uint32 public constant RUNE_ID_AETHER_GRAY = 2221;
    uint32 public constant RUNE_ID_AETHER_GRAY_2 = 2222;
    uint32 public constant RUNE_ID_AETHER_BROWN = 2223;
    uint32 public constant RUNE_ID_AETHER_BROWN_2 = 2224;
    uint32 public constant RUNE_ID_AETHER_BLACK = 2225;
    uint32 public constant RUNE_ID_AETHER_BLACK_2 = 2226;
    uint32 public constant RUNE_ID_AETHER_RAINBOW = 2227;
    uint32 public constant RUNE_ID_AETHER_RAINBOW_2 = 2228;

    // Epic Elemental Runes
    uint32 public constant RUNE_ID_NEUTRAL_1 = 3000;
    uint32 public constant RUNE_ID_NEUTRAL_2 = 3001;
    uint32 public constant RUNE_ID_FIRE_1 = 3010;
    uint32 public constant RUNE_ID_FIRE_2 = 3011;
    uint32 public constant RUNE_ID_WATER_1 = 3020;
    uint32 public constant RUNE_ID_WATER_2 = 3021;
    uint32 public constant RUNE_ID_NATURE_1 = 3030;
    uint32 public constant RUNE_ID_NATURE_2 = 3031;
    uint32 public constant RUNE_ID_EARTH_1 = 3040;
    uint32 public constant RUNE_ID_EARTH_2 = 3041;
    uint32 public constant RUNE_ID_WIND_1 = 3050;
    uint32 public constant RUNE_ID_WIND_2 = 3051;
    uint32 public constant RUNE_ID_ICE_1 = 3060;
    uint32 public constant RUNE_ID_ICE_2 = 3061;
    uint32 public constant RUNE_ID_LIGHTNING_1 = 3070;
    uint32 public constant RUNE_ID_LIGHTNING_2 = 3071;
    uint32 public constant RUNE_ID_LIGHT_1 = 3080;
    uint32 public constant RUNE_ID_LIGHT_2 = 3081;
    uint32 public constant RUNE_ID_DARK_1 = 3090;
    uint32 public constant RUNE_ID_DARK_2 = 3091;
    uint32 public constant RUNE_ID_METAL_1 = 3100;
    uint32 public constant RUNE_ID_METAL_2 = 3101;
    uint32 public constant RUNE_ID_NETHER_1 = 3110;
    uint32 public constant RUNE_ID_NETHER_2 = 3111;
    uint32 public constant RUNE_ID_AETHER_1 = 3120;
    uint32 public constant RUNE_ID_AETHER_2 = 3121;

    // Legendary Elemental Runes
    uint32 public constant RUNE_ID_LEGENDARY_NEUTRAL = 4000;
    uint32 public constant RUNE_ID_LEGENDARY_FIRE = 4001;
    uint32 public constant RUNE_ID_LEGENDARY_WATER = 4002;
    uint32 public constant RUNE_ID_LEGENDARY_NATURE = 4003;
    uint32 public constant RUNE_ID_LEGENDARY_EARTH = 4004;
    uint32 public constant RUNE_ID_LEGENDARY_WIND = 4005;
    uint32 public constant RUNE_ID_LEGENDARY_ICE = 4006;
    uint32 public constant RUNE_ID_LEGENDARY_LIGHTNING = 4007;
    uint32 public constant RUNE_ID_LEGENDARY_LIGHT = 4008;
    uint32 public constant RUNE_ID_LEGENDARY_DARK = 4009;
    uint32 public constant RUNE_ID_LEGENDARY_METAL = 4010;
    uint32 public constant RUNE_ID_LEGENDARY_NETHER = 4011;
    uint32 public constant RUNE_ID_LEGENDARY_AETHER = 4012;

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
}

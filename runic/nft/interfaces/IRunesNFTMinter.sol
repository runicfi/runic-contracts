// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/RunicNFTLib.sol";

interface IRunesNFTMinter {
    function maxSupply() external view returns (uint256 maxSupply);
    function combinePrice() external view returns (uint256 price_);
    function freeMint(address to, uint256 amount) external;
    function mintSpecific(address to, RunicNFTLib.RunicAttributes memory attributes) external returns (uint256 id);
    function mintExtra(address to) external returns (uint256 id);
    function setMaxSupply(uint256 maxSupply) external;
    function setCombinePrice(uint256 price) external;
}
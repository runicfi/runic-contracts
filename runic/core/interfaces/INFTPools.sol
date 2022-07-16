// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPools {
    function getStakedNFTBalance(address account, address nftContract) external view returns (uint256 balance);
    function getStakedNFTPower(address account) external view returns (uint256 power);
}
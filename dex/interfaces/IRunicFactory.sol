// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IUniswapV2Factory.sol";

interface IRunicFactory is IUniswapV2Factory {
    event Pause();
    event Unpause();

    function paused() external view returns (bool);
    function pause() external;
    function unpause() external;
}

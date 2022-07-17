// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./PegOracleUpgradeable.sol";

contract RuniteOracleUpgradeable is PegOracleUpgradeable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IUniswapV2Pair pair_, address token_, uint256 period_, uint256 startTime_, uint256 startEpoch_) public initializer {
        __RuniteOracle_init(pair_, token_, period_, startTime_, startEpoch_);
    }

    function __RuniteOracle_init(IUniswapV2Pair pair_, address token_, uint256 period_, uint256 startTime_, uint256 startEpoch_) internal onlyInitializing {
        __PegOracle_init_unchained(pair_, token_);
        __Epoch_init_unchained(period_, startTime_, startEpoch_);
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Babylonian.sol";
import "./lib/FixedPoint.sol";
import "./lib/UniswapV2OracleLibrary.sol";
import "./utils/EpochUpgradeable.sol";
import "../../dex/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IUpdate.sol";

/**
 * @title PegOracle
 * fixed window oracle that recomputes the average price for the entire period once every period
 * note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
 */
contract PegOracleUpgradeable is EpochUpgradeable, IOracle, IUpdate {
    using FixedPoint for *;
    using SafeMath for uint256;
    address public token;

    // uniswap
    address public token0;
    address public token1;
    IUniswapV2Pair public pair;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);

    error InvalidToken(); // 0xc1ab6dc1
    error NoReserves(); // 0xd8b9cde1

    function __PegOracle_init_unchained(IUniswapV2Pair pair_, address token_) internal onlyInitializing {
        pair = pair_;
        token = token_;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        if(reserve0 == 0 || reserve1 == 0) revert NoReserves(); // ensure that there's liquidity in the pair
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IOracle).interfaceId ||
        interfaceId == type(IUpdate).interfaceId;
    }

    /**
     * @notice Updates 1-day EMA price from Uniswap.
     */
    function update() external override(IOracle, IUpdate) checkEpoch {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if(timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0Cumulative, price1Cumulative);
    }

    /**
     * @notice note this will always return 0 before update has been called successfully for the first time.
     */
    function consult(address token_, uint256 amountIn_) external view override returns (uint144 amountOut) {
        if(token_ == token0) {
            amountOut = price0Average.mul(amountIn_).decode144();
        } else {
            if(token_ != token1) revert InvalidToken();
            amountOut = price1Average.mul(amountIn_).decode144();
        }
    }

    function twap(address token_, uint256 amountIn_) external view override returns (uint144 amountOut) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if(token_ == token0) {
            amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(amountIn_).decode144();
        } else if(token_ == token1) {
            amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(amountIn_).decode144();
        }
        return amountOut;
    }

    function getPegPrice() external view override returns (uint256 amountOut) {
        if(token == token0) {
            return price0Average.mul(1 ether).decode144();
        } else {
            return price1Average.mul(1 ether).decode144();
        }
    }

    function getPegPriceUpdated() external view override returns (uint256 amountOut) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if(token == token0) {
            return FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(1 ether).decode144();
        } else {
            return FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(1 ether).decode144();
        }
    }

    uint256[41] private __gap;
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../dex/interfaces/IUniswapV2Pair.sol";
import "../../dex/interfaces/IUniswapV2Router.sol";
import "../../dex/lib/UniswapV2Library.sol";
import "../../lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";

/**
 * @title LiquiditySale
 * Allows providing liquidity in exchange for locked liquidity tokens which can be unlocked in time
 * This must be excluded to and from tax
 * No one can buy from liquidity pair until it is set to be buyable but liquidity can be added
 */
contract LiquiditySale is AccessControlEnumerable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;
    address public constant WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // change to the wrapped gas token
    address public router;
    address public runic;
    address public fate;
    address public runite;
    address public usdc;
    address public runicLp; // Runic-FTM LP
    address public xRunicLp; // locked Runic-FTM LP
    address public fateLp; // Fate-FTM LP
    address public xFateLp; // locked Fate-FTM LP
    address public runiteLp; // Runite-USDC LP
    address public xRuniteLp; // locked Runite-USDC LP
    uint256 public startTime; // time to start
    uint256 public claimTime; // time to claim lp tokens from locked tokens
    uint256 public maxRunicAmountFTM; // max amount for address
    uint256 public maxFateAmountFTM; // max amount for address
    uint256 public maxRuniteAmountUSDC; // max amount for address
    uint256 public runicLpSlippage = 5; // 0.5% slippage
    uint256 public fateLpSlippage = 5; // 0.5% slippage
    uint256 public runiteLpSlippage = 5; // 0.5% slippage
    mapping(address => uint256) public userRunicAmount; // amount user bought in ETH to check against limit
    mapping(address => uint256) public userFateAmount; // amount user bought in ETH to check against limit
    mapping(address => uint256) public userRuniteAmount; // amount user bought in USDC to check against limit
    bool started;

    receive() external payable {}
    fallback() external payable {}

    error MaxAmount(string);    // 0x72b397c9
    error LowBalance(string);   // 0xfd0074dc
    error PayableAmount();      // 0xf741e218
    error TooLate();            // 0xecdd1c29
    error TooSoon();            // 0x6fed7d85
    error ZeroAmount();         // 0x1f2a2005

    constructor() {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    /**
     * @notice Set contracts and amounts before start
     */
    function setContracts(address router_, address runic_, address fate_, address runite_, address usdc_) external onlyRole(AccessControl.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        router = router_;
        runic = runic_;
        fate = fate_;
        runite = runite_;
        usdc = usdc_;
    }

    /**
     * @notice Sets locked lp tokens
     */
    function setLp(address runicLp_, address xRunicLp_, address fateLp_, address xFateLp_, address runiteLp_, address xRuniteLp_) external onlyRole(AccessControl.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        runicLp = runicLp_;
        xRunicLp = xRunicLp_;
        fateLp = fateLp_;
        xFateLp = xFateLp_;
        runiteLp = runiteLp_;
        xRuniteLp = xRuniteLp_;
    }

    /**
     * @notice Sets max amount that can be purchased
     * Can be adjusted after start
     */
    function setMaxAmount(uint256 maxRunicAmountFTM_, uint256 maxFateAmountFTM_, uint256 maxRuniteAmountUSDC_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        maxRunicAmountFTM = maxRunicAmountFTM_;
        maxFateAmountFTM = maxFateAmountFTM_;
        maxRuniteAmountUSDC = maxRuniteAmountUSDC_;
    }

    /**
     * @notice Sets slippage for making LP
     */
    function setSlippage(uint256 runicLpSlippage_, uint256 fateLpSlippage_, uint256 runiteLpSlippage_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        runicLpSlippage = runicLpSlippage_;
        fateLpSlippage = fateLpSlippage_;
        runiteLpSlippage = runiteLpSlippage_;
    }

    /**
     * @notice Can adjust claimTime before start
     */
    function setClaimTime(uint256 claimTime_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started && claimTime_ > claimTime) revert TooLate();
        // Allow for lowering claimTime in case claimTime is set too long
        claimTime = claimTime_;
    }

    function start() external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(block.timestamp < startTime) revert TooSoon();
        if(started) revert TooLate();
        started = true;
        startTime = block.timestamp;
        claimTime = startTime + 30 days;
    }

    function setPause(bool pause_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function buyRunicLiquidityTokens() external payable whenNotPaused nonReentrant {
        if(msg.value == 0) revert ZeroAmount();
        if(!started) revert TooSoon();
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(IUniswapV2Pair(runicLp).factory(), runic, WETH);
        uint256 amountRunic = UniswapV2Library.quote(msg.value, reserveB, reserveA);
        if(amountRunic > IERC20(runic).balanceOf(address(this))) revert LowBalance(amountRunic.toString());

        uint256 amountEthMin = (msg.value * (1000 - runicLpSlippage)) / 1000;
        uint256 amountRunicMin = (amountRunic * (1000 - runicLpSlippage)) / 1000;

        userRunicAmount[msg.sender] += msg.value;
        if(userRunicAmount[msg.sender] > maxRunicAmountFTM) revert MaxAmount(userRunicAmount[msg.sender].toString());

        _addLiquidityETH(runic, amountRunic, msg.value, amountRunicMin, amountEthMin);
    }

    function buyFateLiquidityTokens() external payable whenNotPaused nonReentrant {
        if(msg.value == 0) revert ZeroAmount();
        if(!started) revert TooSoon();
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(IUniswapV2Pair(fateLp).factory(), fate, WETH);
        uint256 amountFate = UniswapV2Library.quote(msg.value, reserveB, reserveA);
        if(amountFate > IERC20(fate).balanceOf(address(this))) revert LowBalance(amountFate.toString());

        uint256 amountEthMin = (msg.value * (1000 - fateLpSlippage)) / 1000;
        uint256 amountFateMin = (amountFate * (1000 - fateLpSlippage)) / 1000;

        userFateAmount[msg.sender] += msg.value;
        if(userFateAmount[msg.sender] > maxFateAmountFTM) revert MaxAmount(userFateAmount[msg.sender].toString());

        _addLiquidityETH(fate, amountFate, msg.value, amountFateMin, amountEthMin);
    }

    function buyRuniteLiquidityTokens(uint256 amountUsdc_) external whenNotPaused nonReentrant {
        if(amountUsdc_ == 0) revert ZeroAmount();
        if(!started) revert TooSoon();
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(IUniswapV2Pair(runiteLp).factory(), runite, usdc);
        uint256 amountRunite = UniswapV2Library.quote(amountUsdc_, reserveB, reserveA);
        if(amountRunite > IERC20(runite).balanceOf(address(this))) revert LowBalance(amountRunite.toString());

        uint256 amountUsdcMin = (amountUsdc_ * (1000 - runiteLpSlippage)) / 1000;
        uint256 amountRuniteMin = (amountRunite * (1000 - runiteLpSlippage)) / 1000;

        userRuniteAmount[msg.sender] += amountUsdc_;
        if(userRuniteAmount[msg.sender] > maxRuniteAmountUSDC) revert MaxAmount(amountRunite.toString());

        _addLiquidity(runite, usdc, amountRunite, amountUsdc_, amountRuniteMin, amountUsdcMin);
    }

    /**
     * @notice Use sender's eth and this contract's tokenA
     */
    function _addLiquidityETH(address token_, uint256 amtTokenA_, uint256 amtEth_, uint256 amtTokenAMin_, uint256 amtEthMin_) internal returns (uint256, uint256, uint256) {
        if(amtTokenA_ == 0 || amtEth_ == 0) revert ZeroAmount();
        _approveTokenIfNeeded(token_, router);

        (uint256 resultAmtTokenA, uint256 resultAmtEth, uint256 liquidity) = IUniswapV2Router(router).addLiquidityETH{value: amtEth_}(
            token_,
            amtTokenA_,
            amtTokenAMin_,
            amtEthMin_,
            address(this), // send liquidity token to this
            block.timestamp
        );
        // mint sender xLP
        if(token_ == runic) {
            IERC20Mintable(xRunicLp).mint(msg.sender, liquidity);
        } else if(token_ == fate) {
            IERC20Mintable(xFateLp).mint(msg.sender, liquidity);
        }

        return (resultAmtTokenA, resultAmtEth, liquidity);
    }

    /**
     * @notice Add liquidity tax free
     */
    function _addLiquidity(address tokenA_, address tokenB_, uint256 amtTokenA_, uint256 amtTokenB_, uint256 amtTokenAMin_, uint256 amtTokenBMin_) internal returns (uint256, uint256, uint256) {
        if(amtTokenA_ == 0 || amtTokenB_ == 0) revert ZeroAmount();

        IERC20(tokenB_).safeTransferFrom(msg.sender, address(this), amtTokenB_);
        _approveTokenIfNeeded(tokenA_, router);
        _approveTokenIfNeeded(tokenB_, router);

        (uint256 resultAmtTokenA, uint256 resultAmtTokenB, uint256 liquidity) = IUniswapV2Router(router).addLiquidity(
            tokenA_,
            tokenB_,
            amtTokenA_,
            amtTokenB_,
            amtTokenAMin_,
            amtTokenBMin_,
            address(this),
            block.timestamp
        );
        // mint sender xLP
        if(tokenA_ == runite) {
            IERC20Mintable(xRuniteLp).mint(msg.sender, liquidity);
        }
        return (resultAmtTokenA, resultAmtTokenB, liquidity);
    }

    function _approveTokenIfNeeded(address token_, address router_) private {
        if(IERC20(token_).allowance(address(this), router_) == 0) {
            IERC20(token_).safeApprove(router_, type(uint256).max);
        }
    }

    function claimRunicLpTokens() external nonReentrant {
        if(block.timestamp < claimTime) revert TooSoon();
        uint256 amount_ = IERC20(xRunicLp).balanceOf(msg.sender);
        IERC20Burnable(xRunicLp).burnFrom(msg.sender, amount_);
        IERC20(runicLp).safeTransfer(msg.sender, amount_);
    }

    function claimFateLpTokens() external nonReentrant {
        if(block.timestamp < claimTime) revert TooSoon();
        uint256 amount_ = IERC20(xFateLp).balanceOf(msg.sender);
        IERC20Burnable(xFateLp).burnFrom(msg.sender, amount_);
        IERC20(fateLp).safeTransfer(msg.sender, amount_);
    }

    function claimRuniteLpTokens() external nonReentrant {
        if(block.timestamp < claimTime) revert TooSoon();
        uint256 amount_ = IERC20(xRuniteLp).balanceOf(msg.sender);
        IERC20Burnable(xRuniteLp).burnFrom(msg.sender, amount_);
        IERC20(runiteLp).safeTransfer(msg.sender, amount_);
    }

    /**
     * @notice Allow 30 days after claimTime to recover any tokens
     */
    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(block.timestamp < claimTime + 30 days) revert TooSoon();
        token_.safeTransfer(to_, amount_);
    }
}
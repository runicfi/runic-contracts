// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../lib/AccessControlConstants.sol";
import "../../../token/ERC20/extensions/IERC20Mintable.sol";
import "../interfaces/IUpdate.sol";

/**
 * @title FundsReserve
 * Handles distribution of funds
 */
contract FundsReserve is AccessControlEnumerable, ReentrancyGuard, IUpdate {
    using SafeERC20 for IERC20;
    address public runic;
    address public fate;
    address public runite;
    address public devFunds;
    address public daoFunds;
    address public liquidityFunds;
    // initial dev funds
    uint256 public runicInitialDevFunds = 0 ether;
    uint256 public fateInitialDevFunds = 0 ether;
    uint256 public runiteInitialDevFunds = 0 ether;
    // initial liquidity
    uint256 public runicInitialLiquidity = 250_000 ether;
    uint256 public fateInitialLiquidity = 100 ether;
    uint256 public runiteInitialLiquidity = 100_000 ether;
    // vested funds
    uint256 public constant runicPerSecond = 0.02 ether;
    uint256 public constant runitePerSecond = 0.02 ether;
    uint256 public constant fateTotalFunds = 49_800 ether;
    uint256 public constant fateVestingDuration = 730 days;
    uint256 public fateDevAlloc = 20_000;
    uint256 public fateDaoAlloc = 29_800;
    uint256 public fateTotalAlloc = 49_800;
    uint256 public startTime;
    uint256 public lastClaimTime;
    bool public started;

    receive() payable external {}
    fallback() payable external {}

    error TooLate(); // 0xecdd1c29

    constructor() {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Setup addresses
     * Must exclude each address from tax
     */
    function setup(address runic_, address fate_, address runite_, address devFunds_, address daoFunds_, address liquidityFunds_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        runic = runic_;
        fate = fate_;
        runite = runite_;
        devFunds = devFunds_;
        daoFunds = daoFunds_;
        liquidityFunds = liquidityFunds_;
    }

    /**
     * @notice Allow adjustment of initial funds before start
     */
    function setInitialFunds(uint256 runicInitialDevFunds_, uint256 fateInitialDevFunds_, uint256 runiteInitialDevFunds_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        runicInitialDevFunds = runicInitialDevFunds_;
        fateInitialDevFunds = fateInitialDevFunds_;
        runiteInitialDevFunds = runiteInitialDevFunds_;
    }

    /**
     * @notice Allow adjustment of initial liquidity before start
     */
    function setInitialLiquidity(uint256 runicInitialLiquidity_, uint256 fateInitialLiquidity_, uint256 runiteInitialLiquidity_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        runicInitialLiquidity = runicInitialLiquidity_;
        fateInitialLiquidity = fateInitialLiquidity_;
        runiteInitialLiquidity = runiteInitialLiquidity_;
    }

    /**
     * @notice send initial funds
     */
    function start() external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        if(started) revert TooLate();
        // initial dev funds
        IERC20Mintable(runic).mint(devFunds, runicInitialDevFunds);
        IERC20Mintable(fate).mint(devFunds, fateInitialDevFunds);
        IERC20Mintable(runite).mint(devFunds, runiteInitialDevFunds);

        // initial liquidity
        IERC20Mintable(runic).mint(liquidityFunds, runicInitialLiquidity);
        IERC20Mintable(fate).mint(liquidityFunds, fateInitialLiquidity);
        IERC20Mintable(runite).mint(liquidityFunds, runiteInitialLiquidity);

        started = true;
        lastClaimTime = block.timestamp;
        startTime = block.timestamp;
    }

    function setDevFunds(address devFunds_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        devFunds = devFunds_;
    }

    function setDaoFunds(address daoFunds_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        daoFunds = daoFunds_;
    }

    function setFateAlloc(uint256 devAlloc_, uint256 daoAlloc_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        update();
        fateDevAlloc = devAlloc_;
        fateDaoAlloc = daoAlloc_;
        fateTotalAlloc = devAlloc_ + daoAlloc_;
    }

    function _distributeRunic() internal {
        uint256 amount = (block.timestamp - lastClaimTime) * runicPerSecond;
        IERC20Mintable(runic).mint(devFunds, amount);
    }

    function _distributeRunite() internal {
        uint256 amount = (block.timestamp - lastClaimTime) * runitePerSecond;
        IERC20Mintable(runite).mint(devFunds, amount);
    }

    function getFatePerSecond() public pure returns (uint256) {
        return fateTotalFunds / fateVestingDuration;
    }

    function _distributeFate() internal {
        uint256 devAmount = (block.timestamp - lastClaimTime) * (fateDevAlloc / fateTotalAlloc) * getFatePerSecond();
        uint256 daoAmount = (block.timestamp - lastClaimTime) * (fateDaoAlloc / fateTotalAlloc) * getFatePerSecond();
        if(lastClaimTime < startTime + fateVestingDuration) {
            IERC20Mintable(fate).mint(devFunds, devAmount);
            IERC20Mintable(fate).mint(daoFunds, daoAmount);
        }
    }

    /**
     * @notice allows this contract to be automatically updated by hooking onto another contract
     */
    function update() public override nonReentrant {
        _distributeRunic();
        _distributeFate();
        _distributeRunite();
        lastClaimTime = block.timestamp;
    }

    /**
     * @notice Allows withdrawing of any funds accidentally sent here
     */
    function withdraw() external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent);
    }

    /**
     * @notice Allows withdrawing of any funds accidentally sent here
     */
    function withdrawERC20Token(address token_, uint256 amount_) external virtual onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        IERC20(token_).safeTransfer(msg.sender, amount_);
    }
}

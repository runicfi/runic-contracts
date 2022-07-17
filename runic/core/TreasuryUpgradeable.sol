// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Babylonian.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IBoardroomFee.sol";
import "./interfaces/IRegulationStats.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IUpdate.sol";
import "../../lib/AccessControlConstants.sol";
import "../../token/ERC20/extensions/IERC20Burnable.sol";
import "../../token/ERC20/extensions/IERC20Mintable.sol";

/**
 * @title Treasury
 */
contract TreasuryUpgradeable is ContractGuard, AccessControlEnumerableUpgradeable, UUPSUpgradeable, ITreasury {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Boardroom {
        uint256 alloc; // allocation out of 10000 for rewards
        uint32 category; // boardroom category
    }

    uint32 public constant BOARDROOM_CATEGORY_ERC20 = 0;
    uint32 public constant BOARDROOM_CATEGORY_ERC721 = 1;
    uint256 public constant PERIOD = 6 hours;

    bool public setupDone;
    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 public override epoch;
    uint256 private _epochLength;
    uint256 public epochSupplyContractionLeft;
    EnumerableSetUpgradeable.AddressSet private _excludedFromTotalSupply; // exclusions from total supply
    EnumerableSetUpgradeable.AddressSet private _updateHooks; // update hook contracts called on allocateSeigniorage
    EnumerableSetUpgradeable.AddressSet private _boardrooms; // boardroom address
    mapping(address => Boardroom) private _boardroomsInfo; // holds Boardroom struct
    uint256 boardroomsTotalAllocPoints; // total allocation points of boardrooms
    address public pegToken; // pegged token
    address public bond; // bond token
    address public oracle; // oracle
    uint256 public pegTokenPriceOne;      // pegged token price
    uint256 public pegTokenPriceCeiling;  // pegged token price ceiling
    uint256 public seigniorageSaved;    // saved pegged token in treasury
    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;
    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;
    uint256 public bootstrapEpochs; // 28 first epochs (1 week) with 4.5% expansion regardless of price
    uint256 public bootstrapSupplyExpansionPercent;
    bool public stableMaxSupplyExpansion; // use stable max supply expansion
    uint256 public override previousEpochPegTokenPrice;
    uint256 public pegTokenSupplyTarget; // alternative expansion system
    uint256 public allocateSeigniorageSalary; // payment for calling allocateSeigniorage
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra during debt phase
    address public daoFund;
    uint256 public daoFundPercent;
    address public devFund;
    uint256 public devFundPercent;
    address public regulationStats;

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 pegTokenAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 pegTokenAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event FundingAdded(uint256 indexed epoch, uint256 timestamp, uint256 price, uint256 expanded, uint256 boardroomFund, uint256 daoFund, uint256 devFund);
    event ErrorString(string reason);
    event ErrorPanic(uint reason);
    event ErrorBytes(bytes reason);

    error AlreadySetup();           // 0x77358691
    error DoesNotExist();           // 0xb0ce7591
    error Exist();                  // 0x65956805
    error FailedToGetPrice();       // 0x3428a74c
    error IndexTooHigh();           // 0xfbf22ac0
    error IndexTooLow();            // 0x9d445a78
    error InvalidBondRate();        // 0x1e81f45c
    error NotEnoughBonds();         // 0xd53d422f
    error NotOpened();              // 0x6d36408a
    error NotOperator();            // 0x7c214f04
    error NotStarted();             // 0x6f312cbd
    error OutOfRange();             // 0x7db3aba7
    error OverMaxDebtRatio();       // 0x12cb9a0a
    error PriceMoved();             // 0x38aa5c15
    error PriceNotEligible();       // 0x91722c5f
    error Token();                  // 0xc2412676
    error TooHigh();                // 0xf2034b4e
    error TooLow();                 // 0x3ca55442
    error TreasuryHasNoBudget();    // 0x72560f29
    error ZeroAddress();            // 0xd92e233d
    error ZeroAmount();             // 0x1f2a2005

    modifier onlyOperator {
        if(!AccessControlUpgradeable.hasRole(AccessControlConstants.OPERATOR_ROLE, msg.sender)) revert NotOperator();
        _;
    }
    
    modifier checkCondition {
        if(block.timestamp < startTime) revert NotStarted();
        _;
    }

    modifier checkEpoch {
        uint256 nextEpochPoint_ = nextEpochPoint();
        if(block.timestamp < nextEpochPoint_) revert NotOpened();
        _;
        lastEpochTime = nextEpochPoint_;
        epoch++;
        epochSupplyContractionLeft = (getPegTokenPrice() > pegTokenPriceCeiling) ? 0 : (getPegTokenCirculatingSupply() * maxSupplyContractionPercent) / 10000;
    }

    modifier notSetup {
        if(setupDone) revert AlreadySetup();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Treasury_init();
    }

    function __Treasury_init() internal onlyInitializing {
        __Treasury_init_unchained();
    }

    function __Treasury_init_unchained() internal onlyInitializing {
        AccessControlUpgradeable._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(AccessControlConstants.OPERATOR_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {}

    function setup(address pegToken_, address bond_, address oracle_, address boardroom_, address nftBoardroom_, uint256 startTime_, uint256 startEpoch_) external notSetup onlyOperator {
        pegToken = pegToken_;
        bond = bond_;
        oracle = oracle_;
        _boardrooms.add(boardroom_);
        _boardroomsInfo[boardroom_].alloc = 5000;    // 50%
        _boardrooms.add(nftBoardroom_);
        _boardroomsInfo[nftBoardroom_].alloc = 5000;
        _boardroomsInfo[nftBoardroom_].category = BOARDROOM_CATEGORY_ERC721;
        boardroomsTotalAllocPoints = 10000;
        startTime = startTime_;
        epoch = startEpoch_;
        _epochLength = PERIOD;
        lastEpochTime = startTime_ - PERIOD;

        pegTokenPriceOne = 10**18;
        pegTokenPriceCeiling = (pegTokenPriceOne * 101) / 100;

        // Tier max expansion percent
        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];
        pegTokenSupplyTarget = 1000000 ether; // alternative expansion system. Supply is the next target to reduce expansion rate

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn token and mint bond)
        maxDebtRatioPercent = 3500; // Upto 35% supply of bond to purchase

        maxDiscountRate = 13e17; // 30% - when purchasing bond
        maxPremiumRate = 13e17; // 30% - when redeeming bond

        premiumThreshold = 110;
        premiumPercent = 7000; // 70% premium

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 28;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20Upgradeable(pegToken).balanceOf(address(this));

        // incentive to allocate seigniorage
        allocateSeigniorageSalary = 0.2 ether;

        setupDone = true;
        emit Initialized(msg.sender, block.number);
    }

    /** ================================================================================================================
     * @notice Epoch
     * ============================================================================================================== */

    function nextEpochPoint() public view override returns (uint256) {
        return lastEpochTime + _epochLength;
    }

    function setEpochLength(uint256 epochLength_) external onlyOperator {
        _epochLength = epochLength_;
    }

    /** ================================================================================================================
     * @notice Oracle
     * ============================================================================================================== */

    function setOracle(address oracle_) external onlyOperator {
        oracle = oracle_;
    }

    function getPegTokenPrice() public view override returns (uint256 price) {
        price = 0;
        try IOracle(oracle).consult(pegToken, 1e18) returns (uint144 price_) {
            return uint256(price_);
        } catch {
            revert FailedToGetPrice();
        }
    }

    function getPegTokenPriceUpdated() public view override returns (uint256 price) {
        price = 0;
        try IOracle(oracle).twap(pegToken, 1e18) returns (uint144 price_) {
            return uint256(price_);
        } catch {
            revert FailedToGetPrice();
        }
    }

    /**
     * @notice Oracle may revert if there is a math error or operator is not set to Treasury
     * If there is an issue with the oracle contract, then it can be changed
     */
    function _updatePegTokenPrice() internal {
        try IOracle(oracle).update() {
        } catch Error(string memory reason) {
            emit ErrorString(reason);
        } catch Panic(uint reason) {
            emit ErrorPanic(reason);
        } catch (bytes memory reason) {
            emit ErrorBytes(reason);
        }
    }

    /** ================================================================================================================
     * @notice RegulationStats
     * Sets the regulation stats that keeps track of data
     * ============================================================================================================== */

    function setRegulationStats(address regulationStats_) external onlyOperator {
        regulationStats = regulationStats_;
    }

    /** ================================================================================================================
     * @notice Funds
     * ============================================================================================================== */

    /**
     * @notice Budget
     */
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function setExtraFunds(address daoFund_, uint256 daoFundPercent_, address devFund_, uint256 devFundPercent_) external onlyOperator {
        if(daoFund_ == address(0)) revert ZeroAddress();
        if(daoFundPercent_ > 3000) revert OutOfRange(); // <= 30%
        if(devFund_ == address(0)) revert ZeroAddress();
        if(devFundPercent_ > 3000) revert OutOfRange(); // <= 30%
        daoFund = daoFund_;
        daoFundPercent = daoFundPercent_;
        devFund = devFund_;
        devFundPercent = devFundPercent_;
    }

    function setAllocateSeigniorageSalary(uint256 allocateSeigniorageSalary_) external onlyOperator {
        if(allocateSeigniorageSalary_ > 10 ether) revert TooHigh();
        allocateSeigniorageSalary = allocateSeigniorageSalary_;
    }

    /** ================================================================================================================
     * @notice Boardrooms
     * ============================================================================================================== */

    function getBoardrooms() external view returns (address[] memory) {
        return _boardrooms.values();
    }

    function getBoardroomInfo(address boardroom_) external view returns (uint256 alloc_, uint32 category_) {
        Boardroom memory room = _boardroomsInfo[boardroom_];
        alloc_ = room.alloc;
        category_ = room.category;
    }

    function addBoardroom(address boardroom_, uint256 alloc_, uint32 category_) external onlyOperator {
        if(_boardrooms.contains(boardroom_)) revert Exist();
        _boardrooms.add(boardroom_);
        Boardroom memory room;
        room.alloc = alloc_;
        room.category = category_;
        _boardroomsInfo[boardroom_] = room;
        boardroomsTotalAllocPoints += alloc_;
    }

    function removeBoardroom(address boardroom_) external onlyOperator {
        if(!_boardrooms.contains(boardroom_)) revert DoesNotExist();
        boardroomsTotalAllocPoints -= _boardroomsInfo[boardroom_].alloc;
        delete _boardroomsInfo[boardroom_].alloc;
        delete _boardroomsInfo[boardroom_].category;
        _boardrooms.remove(boardroom_);
    }

    function setBoardroom(address boardroom_, uint256 alloc_) external onlyOperator {
        if(!_boardrooms.contains(boardroom_)) revert DoesNotExist();
        boardroomsTotalAllocPoints = (boardroomsTotalAllocPoints - _boardroomsInfo[boardroom_].alloc) + alloc_;
        Boardroom memory room;
        room.alloc = alloc_;
        room.category = _boardroomsInfo[boardroom_].category;
        _boardroomsInfo[boardroom_] = room;
    }

    /**
     * @notice Send to each boardroom
     */
    function _sendToBoardroom(uint256 amount_, uint256 expanded_) internal {
        IERC20Mintable(pegToken).mint(address(this), amount_);

        uint256 daoFundAmount_;
        if(daoFundPercent > 0) {
            daoFundAmount_ = (amount_ * daoFundPercent) / 10000;
            IERC20Upgradeable(pegToken).safeTransfer(daoFund, daoFundAmount_);
        }

        uint256 devFundAmount_;
        if(devFundPercent > 0) {
            devFundAmount_ = (amount_ * devFundPercent) / 10000;
            IERC20Upgradeable(pegToken).safeTransfer(devFund, devFundAmount_);
        }

        amount_ -= (daoFundAmount_ + devFundAmount_);

        uint256 amountAdded;
        uint256 amountSendToBoardroom = amount_;
        for(uint256 i; i < _boardrooms.length(); i++) {
            address room = _boardrooms.at(i);
            uint256 amt = (amount_ * _boardroomsInfo[room].alloc) / boardroomsTotalAllocPoints;
            if(amountAdded + amt > amount_) amt = amount_ - amountAdded;
            amountAdded += amt;

            if(amt > 0) {
                if(IBoardroom(room).totalShare() > 0) {
                    IERC20Upgradeable(pegToken).safeIncreaseAllowance(room, amt);
                    IBoardroom(room).allocateSeigniorage(amt);
                } else {
                    // if none is staked then send to devFund
                    devFundAmount_ += amt;
                    IERC20Upgradeable(pegToken).safeTransfer(devFund, amt);
                    amountSendToBoardroom -= amt;
                }
            }
        }
        if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, expanded_, amountSendToBoardroom, daoFundAmount_, devFundAmount_);
        emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, expanded_, amountSendToBoardroom, daoFundAmount_, devFundAmount_);
    }

    /** ================================================================================================================
     * @notice Hook contracts called on each allocation
     * ============================================================================================================== */

    function getUpdateHooks() external view returns (address[] memory) {
        return _updateHooks.values();
    }

    function _callUpdateHooks() internal {
        for(uint256 i; i < _updateHooks.length(); i++) {
            try IUpdate(_updateHooks.at(i)).update() {
            } catch Error(string memory reason) {
                emit ErrorString(reason);
            } catch Panic(uint reason) {
                emit ErrorPanic(reason);
            } catch (bytes memory reason) {
                emit ErrorBytes(reason);
            }
        }
    }

    function addUpdateHook(address hook_) external onlyOperator {
        if(_updateHooks.contains(hook_)) revert Exist();
        _updateHooks.add(hook_);
    }

    function removeUpdateHook(address hook_) external onlyOperator {
        if(!_updateHooks.contains(hook_)) revert DoesNotExist();
        _updateHooks.remove(hook_);
    }

    /** ================================================================================================================
     * @notice Bonds
     * ============================================================================================================== */

    /**
     * @notice Burnable pegToken left
     */
    function getBurnableTokenLeft() public view returns (uint256 burnablePegTokenLeft_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ <= pegTokenPriceOne) {
            uint256 pegTokenSupply_ = getPegTokenCirculatingSupply();
            uint256 bondMaxSupply_ = (pegTokenSupply_ * maxDebtRatioPercent) / 10000;
            uint256 bondSupply_ = IERC20Upgradeable(bond).totalSupply();
            if(bondMaxSupply_ > bondSupply_) {
                uint256 maxMintableBond_ = bondMaxSupply_ - bondSupply_;
                // added to show consistent calculation as redeemBonds()
                uint256 rate_ = getBondDiscountRate();
                if(rate_ > 0) {
                    uint256 maxBurnableToken_ = (maxMintableBond_ * 1e18) / rate_;
                    burnablePegTokenLeft_ = Math.min(epochSupplyContractionLeft, maxBurnableToken_);
                }
            }
        }
        return burnablePegTokenLeft_;
    }

    function getRedeemableBonds() public view returns (uint256 redeemableBonds_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ > pegTokenPriceCeiling) {
            uint256 totalPegToken_ = IERC20Upgradeable(pegToken).balanceOf(address(this));
            uint256 rate_ = getBondPremiumRate();
            if(rate_ > 0) {
                redeemableBonds_ = (totalPegToken_ * 1e18) / rate_;
            }
        }
        return redeemableBonds_;
    }

    function getBondDiscountRate() public view override returns (uint256 rate_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ <= pegTokenPriceOne) {
            if(discountPercent == 0) {
                // no discount
                rate_ = pegTokenPriceOne;
            } else {
                uint256 bondAmount_ = (pegTokenPriceOne * 1e18) / pegTokenPrice_; // to burn 1 pegToken
                uint256 discountAmount_ = ((bondAmount_ - pegTokenPriceOne) * discountPercent) / 10000;
                rate_ = pegTokenPriceOne + discountAmount_;
                if(maxDiscountRate > 0 && rate_ > maxDiscountRate) {
                    rate_ = maxDiscountRate;
                }
            }
        }
        return rate_;
    }

    function getBondPremiumRate() public view override returns (uint256 rate_) {
        uint256 pegTokenPrice_ = getPegTokenPrice();
        if(pegTokenPrice_ > pegTokenPriceCeiling) {
            uint256 pricePremiumThreshold_ = (pegTokenPriceOne * premiumThreshold) / 100;
            if(pegTokenPrice_ >= pricePremiumThreshold_) {
                // price > 1.10
                uint256 premiumAmount_ = ((pegTokenPrice_ - pegTokenPriceOne) * premiumPercent) / 10000;
                rate_ = pegTokenPriceOne + premiumAmount_;
                if (maxPremiumRate > 0 && rate_ > maxPremiumRate) {
                    rate_ = maxPremiumRate;
                }
            } else {
                // no premium bonus
                rate_ = pegTokenPriceOne;
            }
        }
        return rate_;
    }

    function setBondDepletionFloorPercent(uint256 bondDepletionFloorPercent_) external onlyOperator {
        if(bondDepletionFloorPercent_ < 500 || bondDepletionFloorPercent_ > 10000) revert OutOfRange(); // [5%, 100%]
        bondDepletionFloorPercent = bondDepletionFloorPercent_;
    }

    function buyBonds(uint256 pegTokenAmount_, uint256 targetPrice) external override onlyOneBlock checkCondition {
        if(pegTokenAmount_ == 0) revert ZeroAmount(); // cannot purchase bonds with zero amount

        uint256 pegTokenPrice = getPegTokenPrice();
        if(pegTokenPrice != targetPrice) revert PriceMoved();
        if(pegTokenPrice >= pegTokenPriceOne) revert PriceNotEligible(); // price < $1 required otherwise not eligible for bond purchase
        if(pegTokenAmount_ > epochSupplyContractionLeft) revert NotEnoughBonds(); // not enough bond left to purchase

        uint256 rate_ = getBondDiscountRate();
        if(rate_ == 0) revert InvalidBondRate();

        uint256 bondAmount_ = (pegTokenAmount_ * rate_) / 1e18;
        uint256 pegTokenSupply = getPegTokenCirculatingSupply();
        uint256 newBondSupply = IERC20Upgradeable(bond).totalSupply() + bondAmount_;
        if(newBondSupply > (pegTokenSupply * maxDebtRatioPercent) / 10000) revert OverMaxDebtRatio();

        IERC20Burnable(pegToken).burnFrom(msg.sender, pegTokenAmount_);
        IERC20Mintable(bond).mint(msg.sender, bondAmount_);

        epochSupplyContractionLeft -= pegTokenAmount_;
        _updatePegTokenPrice();

        emit BoughtBonds(msg.sender, pegTokenAmount_, bondAmount_);
    }

    function redeemBonds(uint256 bondAmount_, uint256 targetPrice) external override onlyOneBlock checkCondition {
        if(bondAmount_ == 0) revert ZeroAmount(); // cannot redeem bonds with zero amount

        uint256 pegTokenPrice = getPegTokenPrice();
        if(pegTokenPrice != targetPrice) revert PriceMoved();
        if(pegTokenPrice <= pegTokenPriceCeiling) revert PriceNotEligible(); // price > $1.01 otherwise not eligible for bond purchase

        uint256 rate_ = getBondPremiumRate();
        if(rate_ == 0) revert InvalidBondRate();

        uint256 pegTokenAmount_ = (bondAmount_ * rate_) / 1e18;
        if(IERC20Upgradeable(pegToken).balanceOf(address(this)) < pegTokenAmount_) revert TreasuryHasNoBudget();

        seigniorageSaved -= Math.min(seigniorageSaved, pegTokenAmount_);

        IERC20Burnable(bond).burnFrom(msg.sender, bondAmount_);
        IERC20Upgradeable(pegToken).safeTransfer(msg.sender, pegTokenAmount_);

        _updatePegTokenPrice();

        emit RedeemedBonds(msg.sender, pegTokenAmount_, bondAmount_);
    }

    /** ================================================================================================================
     * @notice Expansion
     * ============================================================================================================== */

    function getExcludeFromTotalSupply() external view returns (address[] memory) {
        return _excludedFromTotalSupply.values();
    }

    function excludeFromTotalSupply(address exclude_) external onlyOperator {
        if(_excludedFromTotalSupply.contains(exclude_)) revert();
        _excludedFromTotalSupply.add(exclude_);
    }

    function includeFromTotalSupply(address include_) external onlyOperator {
        if(!_excludedFromTotalSupply.contains(include_)) revert();
        _excludedFromTotalSupply.remove(include_);
    }

    function getPegTokenCirculatingSupply() public view override returns (uint256) {
        IERC20Upgradeable pegTokenErc20 = IERC20Upgradeable(pegToken);
        uint256 totalSupply = pegTokenErc20.totalSupply();
        uint256 balanceExcluded;
        for(uint256 entryId; entryId < _excludedFromTotalSupply.length(); entryId++) {
            balanceExcluded += pegTokenErc20.balanceOf(_excludedFromTotalSupply.at(entryId));
        }
        return totalSupply - balanceExcluded;
    }

    function getPegTokenExcludedSupply() public view override returns (uint256) {
        IERC20Upgradeable pegTokenErc20 = IERC20Upgradeable(pegToken);
        uint256 balanceExcluded;
        for(uint256 entryId; entryId < _excludedFromTotalSupply.length(); entryId++) {
            balanceExcluded += pegTokenErc20.balanceOf(_excludedFromTotalSupply.at(entryId));
        }
        return balanceExcluded;
    }

    function setPegTokenPriceCeiling(uint256 priceCeiling_) external onlyOperator {
        if(priceCeiling_ < pegTokenPriceOne || priceCeiling_ > (pegTokenPriceOne * 120) / 100) revert OutOfRange(); // [$1.0, $1.2]
        pegTokenPriceCeiling = priceCeiling_;
    }

    /**
     * @notice Sets the max percent for expansion
     */
    function setMaxSupplyExpansionPercents(uint256 maxSupplyExpansionPercent_) external onlyOperator {
        if(maxSupplyExpansionPercent_ < 10 || maxSupplyExpansionPercent_ > 1000) revert OutOfRange(); // [0.1%, 10%]
        maxSupplyExpansionPercent = maxSupplyExpansionPercent_;
    }

    /**
     * @notice Sets the supply tiers
     */
    function setSupplyTiersEntry(uint8 index_, uint256 value_) external onlyOperator returns (bool) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= 9) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > supplyTiers[index_ - 1]);
        }
        if(index_ < 8) {
            require(value_ < supplyTiers[index_ + 1]);
        }
        supplyTiers[index_] = value_;
        return true;
    }

    /**
     * @notice Sets the max expansion for each supply tiers
     */
    function setMaxExpansionTiersEntry(uint8 index_, uint256 value_) external onlyOperator returns (bool) {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= 9) revert IndexTooHigh();
        if(value_ < 10 || value_ > 1000) revert OutOfRange(); // [0.1%, 10%]
        maxExpansionTiers[index_] = value_;
        return true;
    }

    /**
     * @notice Sets the bootstrap expansion regardless of price
     */
    function setBootstrap(uint256 bootstrapEpochs_, uint256 bootstrapSupplyExpansionPercent_) external onlyOperator {
        if(bootstrapEpochs_ > 120) revert OutOfRange(); // <= 1 month
        if(bootstrapSupplyExpansionPercent_ < 100 || bootstrapSupplyExpansionPercent_ > 1000) revert OutOfRange(); // [1%, 10%]
        bootstrapEpochs = bootstrapEpochs_;
        bootstrapSupplyExpansionPercent = bootstrapSupplyExpansionPercent_;
    }

    /**
     * @notice Alternative expansion system
     */
    function setStableMaxSupplyExpansion(bool on_) external onlyOperator {
        stableMaxSupplyExpansion = on_;
    }

    /**
     * @notice Sets a supply target to slowly expand for alternative stable expansion system
     */
    function setPegTokenSupplyTarget(uint256 pegTokenSupplyTarget_) external onlyOperator {
        if(pegTokenSupplyTarget_ <= getPegTokenCirculatingSupply()) revert TooLow(); // > current circulating supply
        pegTokenSupplyTarget = pegTokenSupplyTarget_;
    }

    function _calculateMaxSupplyExpansionPercent(uint256 pegTokenSupply_) internal returns (uint256) {
        if(stableMaxSupplyExpansion) {
            return _calculateMaxSupplyExpansionPercentStable(pegTokenSupply_);
        } else {
            return _calculateMaxSupplyExpansionPercentTier(pegTokenSupply_);
        }
    }

    /**
     * @notice Calculate max supply expansion percent with tier system
     */
    function _calculateMaxSupplyExpansionPercentTier(uint256 pegTokenSupply_) internal returns (uint256) {
        for(uint8 tierId = 8; tierId >= 0; tierId--) {
            if(pegTokenSupply_ >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    /**
     * @notice Calculate max supply expansion percent with stable system
     */
    function _calculateMaxSupplyExpansionPercentStable(uint256 pegTokenSupply_) internal returns (uint256) {
        if(pegTokenSupply_ >= pegTokenSupplyTarget) {
            pegTokenSupplyTarget = (pegTokenSupplyTarget * 12500) / 10000; // +25%
            maxSupplyExpansionPercent = (maxSupplyExpansionPercent * 9500) / 10000; // -5%
            if(maxSupplyExpansionPercent < 10) {
                maxSupplyExpansionPercent = 10; // min 0.1%
            }
        }
        return maxSupplyExpansionPercent;
    }

    /**
     * @notice New function for viewing purpose
     */
    function getPegTokenExpansionRate() public view override returns (uint256 rate_) {
        if(epoch < bootstrapEpochs) {
            rate_ = bootstrapSupplyExpansionPercent;
        } else {
            uint256 twap_ = getPegTokenPrice();
            if(twap_ >= pegTokenPriceCeiling) {
                uint256 percentage_ = twap_ - pegTokenPriceOne; // 1% = 1e16
                uint256 mse_ = maxSupplyExpansionPercent * 1e14;
                if(percentage_ > mse_) {
                    percentage_ = mse_;
                }
                rate_ = percentage_ / 1e14;
            }
        }
        return rate_;
    }

    /**
     * @notice New function for viewing purpose
     */
    function getPegTokenExpansionAmount() external view override returns (uint256) {
        uint256 pegTokenSupply = getPegTokenCirculatingSupply() - seigniorageSaved;
        uint256 bondSupply = IERC20Upgradeable(bond).totalSupply();
        uint256 rate_ = getPegTokenExpansionRate();
        if(seigniorageSaved >= (bondSupply * bondDepletionFloorPercent) / 10000) {
            // saved enough to pay debt, mint as usual rate
            return (pegTokenSupply * rate_) / 10000;
        } else {
            // have not saved enough to pay debt, mint more
            uint256 seigniorage_ = (pegTokenSupply * rate_) / 10000;
            return (seigniorage_ * seigniorageExpansionFloorPercent) / 10000;
        }
    }

    /** ================================================================================================================
     * @notice Contraction
     * ============================================================================================================== */

    function setMaxSupplyContractionPercent(uint256 maxSupplyContractionPercent_) external onlyOperator {
        if(maxSupplyContractionPercent_ < 100 || maxSupplyContractionPercent_ > 1500) revert OutOfRange(); // [0.1%, 15%]
        maxSupplyContractionPercent = maxSupplyContractionPercent_;
    }

    function setMaxDebtRatioPercent(uint256 maxDebtRatioPercent_) external onlyOperator {
        if(maxDebtRatioPercent_ < 1000 || maxDebtRatioPercent_ > 10000) revert OutOfRange(); // [10%, 100%]
        maxDebtRatioPercent = maxDebtRatioPercent_;
    }

    function setMaxDiscountRate(uint256 maxDiscountRate_) external onlyOperator {
        maxDiscountRate = maxDiscountRate_;
    }

    function setMaxPremiumRate(uint256 maxPremiumRate_) external onlyOperator {
        maxPremiumRate = maxPremiumRate_;
    }

    function setDiscountPercent(uint256 discountPercent_) external onlyOperator {
        if(discountPercent_ > 20000) revert OutOfRange(); // <= 200%
        discountPercent = discountPercent_;
    }

    function setPremiumThreshold(uint256 premiumThreshold_) external onlyOperator {
        if(premiumThreshold_ < pegTokenPriceCeiling) revert OutOfRange(); // premiumThreshold_ must be >= priceCeiling
        if(premiumThreshold_ > 150) revert OutOfRange(); // premiumThreshold_ must be <= 150 (1.5)
        premiumThreshold = premiumThreshold_;
    }

    function setPremiumPercent(uint256 premiumPercent_) external onlyOperator {
        if(premiumPercent_ > 20000) revert OutOfRange(); // <= 200%
        premiumPercent = premiumPercent_;
    }

    function setMintingFactorForPayingDebt(uint256 mintingFactorForPayingDebt_) external onlyOperator {
        if(mintingFactorForPayingDebt_ < 10000 || mintingFactorForPayingDebt_ > 20000) revert OutOfRange(); // [100%, 200%]
        mintingFactorForPayingDebt = mintingFactorForPayingDebt_;
    }

    /**
     * @notice Allocates seigniorage
     */
    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch {
        _updatePegTokenPrice();
        _callUpdateHooks();
        previousEpochPegTokenPrice = getPegTokenPrice();
        uint256 pegTokenSupply = getPegTokenCirculatingSupply() - seigniorageSaved;
        uint256 seigniorage_;
        if(epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            seigniorage_ = (pegTokenSupply * bootstrapSupplyExpansionPercent) / 10000;
            _sendToBoardroom(seigniorage_, seigniorage_);
        } else {
            if(previousEpochPegTokenPrice > pegTokenPriceCeiling) {
                // Expansion ($PEGTOKEN Price > 1 $PEG): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20Upgradeable(bond).totalSupply();
                uint256 percentage_ = previousEpochPegTokenPrice - pegTokenPriceOne;
                uint256 savedForBond_;
                uint256 savedForBoardroom_;
                uint256 mse_ = _calculateMaxSupplyExpansionPercent(pegTokenSupply) * 1e14;
                if(percentage_ > mse_) {
                    percentage_ = mse_;
                }
                if(seigniorageSaved >= (bondSupply * bondDepletionFloorPercent) / 10000) {
                    // saved enough to pay debt, mint as usual rate
                    savedForBoardroom_ = (pegTokenSupply * percentage_) / 1e18;
                } else {
                    // have not saved enough to pay debt, mint more
                    seigniorage_ = (pegTokenSupply * percentage_) / 1e18;
                    savedForBoardroom_ = (seigniorage_ * seigniorageExpansionFloorPercent) / 10000;
                    savedForBond_ = seigniorage_ - savedForBoardroom_;
                    if(mintingFactorForPayingDebt > 0) {
                        savedForBond_ = (savedForBond_ * mintingFactorForPayingDebt) / 10000;
                    }
                }
                if(savedForBoardroom_ > 0) {
                    _sendToBoardroom(savedForBoardroom_, seigniorage_);
                } else {
                    if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, 0, 0, 0, 0);
                    emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, 0, 0, 0, 0);
                }
                if(savedForBond_ > 0) {
                    seigniorageSaved += savedForBond_;
                    IERC20Mintable(pegToken).mint(address(this), savedForBond_);
                    emit TreasuryFunded(block.timestamp, savedForBond_);
                }
            } else if (previousEpochPegTokenPrice < pegTokenPriceOne) {
                if (regulationStats != address(0)) IRegulationStats(regulationStats).addEpochInfo(epoch + 1, previousEpochPegTokenPrice, 0, 0, 0, 0);
                emit FundingAdded(epoch + 1, block.timestamp, previousEpochPegTokenPrice, 0, 0, 0, 0);
            }
        }
        // send small amount to caller
        if(allocateSeigniorageSalary > 0) {
            IERC20Mintable(pegToken).mint(msg.sender, allocateSeigniorageSalary);
        }
    }

    function governanceRecoverUnsupported(IERC20Upgradeable token_, uint256 amount_, address to_) external onlyOperator {
        // do not allow to drain core tokens
        if(address(token_) == address(pegToken)) revert Token();
        if(address(token_) == address(bond)) revert Token();
        token_.safeTransfer(to_, amount_);
    }

    /**
     * @notice Manually send some amount to a boardroom
     */
    function boardroomAllocateSeigniorage(address boardroom_, uint256 amount_) external onlyOperator {
        IERC20Upgradeable(pegToken).safeIncreaseAllowance(boardroom_, amount_);
        IBoardroom(boardroom_).allocateSeigniorage(amount_);
    }
}
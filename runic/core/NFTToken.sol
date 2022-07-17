// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/INFTPools.sol";
import "../nft/interfaces/INFTPower.sol";
import "./interfaces/INFTToken.sol";
import "./OracleToken.sol";

/**
 * @title NFTToken
 * Requires power within NFT to sell at each twap tier
 */
abstract contract NFTToken is ERC20, OracleToken, INFTToken {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    EnumerableSet.AddressSet internal _nftContracts;      // supported nft contracts
    EnumerableSet.AddressSet internal _nftPoolsContracts; // supported nft pools contracts
    uint256 public override nftPowerRequired;   // the current power of nfts from nft contracts required to send
    bool public autoCalculateNFTPowerRequired;  // should nft power requirement be calculated using the nft tiers
    uint256[] public nftTiersTwaps = [0, 5e17, 6e17, 7e17, 8e17, 9e17, 9.5e17, 1e18, 1.05e18, 1.10e18, 1.20e18, 1.30e18, 1.40e18, 1.50e18];
    uint256[] public nftTiersPowerRequired = [10000, 5000, 2500, 1000, 500, 250, 100, 10, 0, 0, 0, 0, 0, 0];
    mapping(address => bool) public excludedFromNFTAddresses; // addresses excluded from nft requirement when sending
    mapping(address => bool) public excludedToNFTAddresses; // addresses excluded from nft requirement when receiving

    error AutoCalculateNFTPowerRequiredOn();
    error DoesNotExist();
    error Exist();
    error InterfaceNotSupported();
    error NFTPowerRequired();
    error TooHigh();

    constructor() {
        excludedFromNFTAddresses[msg.sender] = true;
        excludedFromNFTAddresses[address(0)] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(INFTToken).interfaceId;
    }

    function isAddressFromNFTExcluded(address address_) external view virtual override returns (bool) {
        return excludedFromNFTAddresses[address_];
    }

    function isAddressToNFTExcluded(address address_) external view virtual override returns (bool) {
        return excludedToNFTAddresses[address_];
    }

    function setNFTTiersTwap(uint8 index_, uint256 value_) external virtual override onlyOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= nftTiersTwaps.length) revert IndexTooHigh();
        if(index_ > 0) {
            require(value_ > nftTiersTwaps[index_ - 1]);
        }
        if(index_ < (nftTiersTwaps.length - 1)) {
            require(value_ < nftTiersTwaps[index_ + 1]);
        }
        nftTiersTwaps[index_] = value_;
    }

    function setNFTTiersPowerRequired(uint8 index_, uint256 value_) external virtual override onlyOperator {
        if(index_ < 0) revert IndexTooLow();
        if(index_ >= nftTiersPowerRequired.length) revert IndexTooHigh();
        nftTiersPowerRequired[index_] = value_;
    }

    function setAutoCalculateNFTPowerRequired(bool enable_) external virtual override onlyOperator {
        autoCalculateNFTPowerRequired = enable_;
    }

    function setNFTPowerRequired(uint256 power_) external virtual override onlyOperator {
        if(autoCalculateNFTPowerRequired) revert AutoCalculateNFTPowerRequiredOn();
        nftPowerRequired = power_;
    }

    function setExcludeFromNFTAddress(address account_, bool exclude_) external virtual override onlyOperator {
        excludedFromNFTAddresses[account_] = exclude_;
    }

    function setExcludeToNFTAddress(address account_, bool exclude_) external virtual override onlyOperator {
        excludedToNFTAddresses[account_] = exclude_;
    }

    function addNFTContract(address nftContract_) external override onlyOperator {
        if(_nftContracts.contains(nftContract_)) revert Exist();
        if(!IERC165(nftContract_).supportsInterface(type(INFTPower).interfaceId)) revert InterfaceNotSupported();
        _nftContracts.add(nftContract_);
    }

    function removeNFTContract(address nftContract_) external override onlyOperator {
        if(!_nftContracts.contains(nftContract_)) revert DoesNotExist();
        _nftContracts.remove(nftContract_);
    }

    function getNFTContracts() external view override returns (address[] memory) {
        return _nftContracts.values();
    }

    function addNFTPoolsContract(address nftPoolsContract_) external override onlyOperator {
        if(_nftPoolsContracts.contains(nftPoolsContract_)) revert Exist();
        if(!IERC165(nftPoolsContract_).supportsInterface(type(INFTPools).interfaceId)) revert InterfaceNotSupported();
        _nftPoolsContracts.add(nftPoolsContract_);
    }

    function removeNFTPoolsContract(address nftPoolsContract_) external override onlyOperator {
        if(!_nftPoolsContracts.contains(nftPoolsContract_)) revert DoesNotExist();
        _nftPoolsContracts.remove(nftPoolsContract_);
    }

    function getNFTPoolsContracts() external view override returns (address[] memory) {
        return _nftPoolsContracts.values();
    }

    function getNFTPowerRequired() external view virtual override returns (uint256 power) {
        uint256 currentPrice = OracleToken.getPriceUpdated();
        if(autoCalculateNFTPowerRequired) {
            for(uint8 tierId = uint8(nftTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(currentPrice >= nftTiersTwaps[tierId]) {
                    return nftTiersPowerRequired[tierId];
                }
            }
        }
        return nftPowerRequired;
    }

    function _updateNFTPowerRequired(uint256 price_) internal virtual returns (uint256) {
        if(autoCalculateNFTPowerRequired) {
            for(uint8 tierId = uint8(nftTiersTwaps.length) - 1; tierId >= 0; tierId--) {
                if(price_ >= nftTiersTwaps[tierId]) {
                    nftPowerRequired = nftTiersPowerRequired[tierId];
                    return nftTiersPowerRequired[tierId];
                }
            }
        }
        return nftPowerRequired;
    }

    /**
     * @notice Ensures that the sender has nft power
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual override {
        uint256 currentNFTPowerRequired;

        if(autoCalculateNFTPowerRequired) {
            uint256 currentPrice = OracleToken.getPriceUpdated();
            currentNFTPowerRequired = _updateNFTPowerRequired(currentPrice);
        }

        if(currentNFTPowerRequired != 0 && !excludedFromNFTAddresses[from_] && !excludedToNFTAddresses[to_]) {
            uint256 power;
            // get power from held nft
            for(uint256 i; i < _nftContracts.length(); i++) {
                address nftContract = _nftContracts.at(i);
                try INFTPower(nftContract).getUserPower(from_) returns (uint256 val) {
                    power += val;
                } catch {}
                if(power >= currentNFTPowerRequired) break;
            }
            // get power from staked nft
            for(uint256 i; i < _nftPoolsContracts.length(); i++) {
                address nftPoolsContract = _nftPoolsContracts.at(i);
                try INFTPools(nftPoolsContract).getStakedNFTPower(from_) returns (uint256 val) {
                    power += val;
                } catch {}
                if(power >= currentNFTPowerRequired) break;
            }
            if(power < currentNFTPowerRequired) revert NFTPowerRequired();
        }
        super._beforeTokenTransfer(from_, to_, amount_);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract Marketplace is OwnableUpgradeable {
    using Strings for uint256;

    struct ItemInfo {
        string category;
        string imgHash;
        uint256 count;
        uint256 priceForBBOSS;
        uint256 priceForUSD;
    }
    mapping (uint256 => ItemInfo) private items;
    uint256 public index;

    address bboss;
    address usdt;

    AggregatorV3Interface internal priceFeed;

    event BuyItem(address indexed buyer, uint256 index, uint256 count, string payMethod, uint256 paidAmount, string email);
    event ListItem(uint256 indexed index, string category, string imgHash, uint256 count, uint256 priceForBBOSS, uint256 priceForUSD);
    
    // constructor() {
    //     index = 0;
    //     // priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // mainnet
    //     priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // testnet
    // }

    function initialize() public initializer {
        __Ownable_init();
        index = 0;
        // priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // mainnet
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // testnet
    }

    function listItem(string memory _category, string memory _imgHash, uint256 _count, uint256 _priceForBBOSS, uint256 _priceForUSD) public onlyOwner {
        require(_count > 0, "count must be over 0");
        items[index] = ItemInfo(_category, _imgHash, _count, _priceForBBOSS, _priceForUSD);

        emit ListItem(index, _category, _imgHash, _count, _priceForBBOSS, _priceForUSD);
        index = index + 1;
    }

    function buyItem(uint256 _index, uint256 _count, string memory _payMethod, string memory _email) public {
        require(_index < index, "Exceeded Index.");
        ItemInfo storage item = items[_index];
        require(item.count >= _count, "Exceeded Count.");
        item.count = item.count - _count;

        if(compareStrings(_payMethod, "BBOSS")) {
            IERC20(bboss).transferFrom(msg.sender, address(this), item.priceForBBOSS * _count);
        } else if(compareStrings(_payMethod, "STABLE")) {
            IERC20(bboss).transferFrom(msg.sender, address(this), item.priceForUSD * _count);
        } else if(compareStrings(_payMethod, "NATIVE")) {
            uint256 nativePrice = getNativePrice();
            uint256 itemPrice = item.priceForUSD / nativePrice;
            IERC20(bboss).transferFrom(msg.sender, address(this), itemPrice * _count);
        }        

        emit BuyItem(msg.sender, _index, _count, _payMethod, item.priceForBBOSS * _count, _email);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getNativePrice() public view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price"); // Check if the price is valid
        return uint256(price * 10**10);
    }
}

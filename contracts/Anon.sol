// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ANON is OwnableUpgradeable, ERC721Upgradeable {  
    using Strings for uint256;
    
    string private _baseURIextended;
    bool public pauseMint;
    IERC721 public koba;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("ANON by ANON", "ANON");
    }

    function manualRevealKoba(uint256[] memory _kobaIds) external {
        require(!pauseMint, "Paused!");
        
        for(uint32 i = 0; i < _kobaIds.length; i++) {
            koba.transferFrom(address(msg.sender), address(this), _kobaIds[i]);
            _safeMint(msg.sender, _kobaIds[i]);
        }
    }

    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function pause() public onlyOwner {
        pauseMint = true;
    }

    function unPause() public onlyOwner {
        pauseMint = false;
    }

    function setKobaAddress(address _koba) public onlyOwner() {
        koba = IERC721(_koba);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ANON is Ownable, ERC721 {  
    using Strings for uint256;
    
    string private _baseURIextended;
    bool public pauseMint = true;
    IERC721 public koba;

    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address _koba) ERC721("ANON by ANON", "ANON") {
        koba = IERC721(_koba);
    }

    function manualRevealKoba(uint256[] calldata _kobaIds) external {
        require(!pauseMint, "Paused!");
        require(_kobaIds.length > 0, "ids length is zero.");
        
        for(uint32 i = 0; i < _kobaIds.length; i++) {
            require(koba.ownerOf(_kobaIds[i]) == msg.sender, "Not Your NFT.");
            koba.transferFrom(address(msg.sender), deadAddress, _kobaIds[i]);
            _safeMint(msg.sender, _kobaIds[i]);
        }
    }

    function withdraw() public onlyOwner {
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

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setPaused() public onlyOwner {
        pauseMint = !pauseMint;
    }

    function setKobaAddress(address _koba) public onlyOwner {
        koba = IERC721(_koba);
    }
}
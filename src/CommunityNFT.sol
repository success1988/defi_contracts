// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityNFT is ERC721, ERC721URIStorage, Ownable {

    uint256 private _nextTokenId;
    mapping(address => bool) public hasMinted;
    
    event MemberNFTMinted(address indexed member, uint256 tokenId, string uri);
    event TokenBurned(uint256 indexed tokenId, address indexed owner);
    
    constructor() ERC721("Community Members", "CMEMBER") Ownable(msg.sender){
        _nextTokenId = 0;
    }
    
    function mintMemberNFT(address memberAddress, string memory uri) 
        public 
        onlyOwner 
    {
        require(!hasMinted[memberAddress], "Member already has NFT");
        require(memberAddress != address(0), "Invalid address");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _safeMint(memberAddress, tokenId);
        _setTokenURI(tokenId, uri);
        hasMinted[memberAddress] = true;
        
        emit MemberNFTMinted(memberAddress, tokenId, uri);
    }

    function batchMintNFTs(address[] memory memberAddresses, string[] memory uris) 
        public 
        onlyOwner 
    {
        require(memberAddresses.length == uris.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            mintMemberNFT(memberAddresses[i], uris[i]);
        }
    }

    // 添加公共的 burn 函数 - 允许 NFT 所有者销毁自己的代币
    function burn(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(
            tokenOwner == msg.sender || isApprovedForAll(tokenOwner, msg.sender) || getApproved(tokenId) == msg.sender,
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
        emit TokenBurned(tokenId, tokenOwner);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
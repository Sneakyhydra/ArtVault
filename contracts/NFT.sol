// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// we will bring in the openzeppelin ERC721 NFT functionality
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NFT is ERC721URIStorage {
    // Counters allow us to keep track of token ids
    using Counters for Counters.Counter;

    // Total number of nfts in the market
    Counters.Counter private _tokenIds;

    // Address of marketplace for NFTs to interact
    address contractAddress;

    constructor(address _marketplaceAddress) ERC721('KryptoBirdz', 'KBZ') {
        contractAddress = _marketplaceAddress;
    }

    // Function to mint a new NFT and assign it a token id
    function mintToken(string memory tokenURI) public returns(uint) {
        // Increase the total number of nfts
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        // Passing creator's address and token id
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        // Give marketplace the approval to transact
        setApprovalForAll(contractAddress, true);

        // Mint the token and set it for sale - return the id to do so
        return newItemId;
    }
}
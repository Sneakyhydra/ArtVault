// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// we will bring in the openzeppelin ERC721 NFT functionality
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NFT is ERC721URIStorage {
    // Counters allow us to keep track of token ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Address of marketplace for NFTs to interact
    address contractAddress;

    constructor(address _marketplaceAddress) ERC721('KryptoBirdz', 'KBZ') {
        contractAddress = _marketplaceAddress;
    }

    function mintToken(string memory tokenURI) public returns(uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        // Passing in id and url
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        // Give the marketplace the approval to transact
        setApprovalForAll(contractAddress, true);

        // Mint the token and set it for sale - return the id to do so
        return newItemId;
    }
}
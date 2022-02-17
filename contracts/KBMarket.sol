// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// we will bring in the openzeppelin ERC721 NFT functionality
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; // Security against transactions for multiple requests
import '@openzeppelin/contracts/utils/Counters.sol';
import 'hardhat/console.sol';

contract KBMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    // Number of items minting, number of transactions, tokens that have not been sold
    // Keep track of tokens total number - tokenId
    // Arrays need to know the length - help to keep track for arrays

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;

    // Determine who is the owner of the contract
    // Charge a listing fee so the owner makes a commission

    address payable owner;
    uint256 listingPrice = 0.045 ether;

    constructor() {
        // Set the owner
        owner = payable(msg.sender);
    }

    struct MarketToken {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // Token id return which marketToken - fetch which one it is
    mapping(uint256=>MarketToken) private idToMarketToken;

    // listen to events from frontend
    event MarketTokenMinted (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Two functions to interact with contract
    // 1. Create a market item to put it up for sale
    // 2. Create a market sale for buying and selling between parties

    function makeMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    ) public payable nonReentrant {
        // nonReentrant is a modifier to prevent reentry attack
        require(price>0, 'Price must be atleast 1 wei');
        require(msg.value==listingPrice, 'Price must be equal to listing price');

        _tokenIds.increment();
        uint itemId = _tokenIds.current();

        // Putting up for sale - bool - no owner
        MarketToken memory marketToken = MarketToken(itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)), price, false);
        idToMarketToken[itemId] = marketToken;

        // NFT Transaction
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
    }

    // Function to conduct transactions and market sales
    function createMarketSale(address nftContract, uint itemId) public payable nonReentrant {
        uint price = idToMarketToken[itemId].price;
        uint tokenId = idToMarketToken[itemId].tokenId;
        require(msg.value==price, 'Price must be equal to listing price');

        // Transfer the amount to the seller
        idToMarketToken[itemId].seller.transfer(msg.value);

        // Transfer the token from contract address to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idToMarketToken[itemId] = MarketToken(itemId, nftContract, tokenId, idToMarketToken[itemId].seller, payable(msg.sender), price, true);
        _tokensSold.increment();

        payable(owner).transfer(listingPrice);
    }

    // Function to fetchMarketItems
    function fetchMarketTokens() public view returns (MarketToken[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldCount = itemCount - _tokensSold.current();
        uint currentIndex = 0;

        MarketToken[] memory items = new MarketToken[](unsoldCount);
        for(uint i=0; i<itemCount; i++) {
            if(idToMarketToken[i+1].owner==address(0)) {
                uint currentId = i+1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }

    // Function to fetch my nfts
    function fetchMyNfts() public view returns (MarketToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
           
        for(uint i=0; i<totalItemCount; i++) {
            if(idToMarketToken[i+1].owner==msg.sender) {
                itemCount++;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);
        for(uint i=0; i<totalItemCount; i++) {
            if(idToMarketToken[i+1].owner==msg.sender) {
                uint currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }

    // Function for returning an array of minted nfts
    function fetchItemsCreated() public view returns (MarketToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for(uint i=0; i<totalItemCount; i++) {
            if(idToMarketToken[i+1].seller==msg.sender) {
                itemCount++;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);
        for(uint i=0; i<totalItemCount; i++) {
            if(idToMarketToken[i+1].seller==msg.sender) {
                uint currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }
}
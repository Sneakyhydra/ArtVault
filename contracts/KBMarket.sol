// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// we will bring in the openzeppelin ERC721 NFT functionality
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; // Security against transactions for multiple requests
import '@openzeppelin/contracts/utils/Counters.sol';
import 'hardhat/console.sol';

contract KBMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    // Total number of nfts in the market
    Counters.Counter private _tokenIds;
    // Total number of nfts sold
    Counters.Counter private _tokensSold;

    // Determine who is the owner of the contract
    // Charge a listing fee so the owner makes a commission
    address payable owner;
    uint256 listingPrice = 0.045 ether;

    // Set the owner
    constructor() {
        owner = payable(msg.sender);
    }

    // Object of an NFT - Stores details of an nft
    struct MarketToken {
        uint itemId;
        uint256 tokenId;
        address nftAddress;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    // Item id to nft mapping
    mapping(uint256=>MarketToken) private idToNft;

    // listen to events from frontend
    event MarketTokenMinted (
        uint indexed itemId,
        uint256 indexed tokenId,
        address indexed nftAddress,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    // Function to get the listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Function to create(mint) NFT
    function mintNft(
        address nftAddress,
        uint tokenId,
        uint price
    ) public payable nonReentrant {
        // nonReentrant is a modifier to prevent reentry attack
        require(price>0, 'Price must be atleast 1 wei');
        // Seller should pay the listing fee
        require(msg.value==listingPrice, 'Pay listing fee');

        // Increase the total number of nfts in the market
        _tokenIds.increment();
        // Set item id to the latest token id
        uint itemId = _tokenIds.current();

        // Create NFT object
        // There is no owner yet
        // Seller is the msg.sender
        // Sold is initialized to false 
        MarketToken memory marketToken = MarketToken(itemId, tokenId, nftAddress, payable(address(0)), payable(msg.sender), price, false);
        
        // Store nft in the database
        idToNft[itemId] = marketToken;

        // NFT Transaction
        // Transfer nft from the seller to the marketplace
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        // Emit the event
        emit MarketTokenMinted(itemId, tokenId, nftAddress, address(0), msg.sender, price, false);
    }

    // Function to buy a NFT
    function buyNft(address nftAddress, uint itemId) public payable nonReentrant {
        // Get price and tokenId of the nft
        uint price = idToNft[itemId].price;
        uint tokenId = idToNft[itemId].tokenId;
        // Buyer should pay the price
        require(msg.value==price, 'Price must be equal to listing price');

        // Transfer the amount to the seller
        idToNft[itemId].seller.transfer(msg.value);

        // Transfer the token from marketplace to the buyer
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        // Set the owner of the nft to the buyer and set sold to true
        idToNft[itemId] = MarketToken(itemId, tokenId, nftAddress, payable(msg.sender), idToNft[itemId].seller, price, true);
        // Increase the number of tokens sold
        _tokensSold.increment();

        // Transfer the listing fee to the marketplace owner
        payable(owner).transfer(listingPrice);
    }

    // Function to get all the unsold nfts
    function fetchUnsoldNfts() public view returns (MarketToken[] memory) {
        // Total number of nfts in the market
        uint itemCount = _tokenIds.current();
        // Total number of unsold nfts in the market
        uint unsoldCount = itemCount - _tokensSold.current();
        
        // Array to store the unsold nfts
        MarketToken[] memory items = new MarketToken[](unsoldCount);
        uint currentIndex = 0;

        // Loop starts from 1 because itemId starts from 1
        for(uint i=1; i<=itemCount; i++) {
            // Check if the nft is unsold i.e. there is no owner
            if(idToNft[i].owner==address(0)) {
                // Get the current nft from the database
                uint currentId = i;
                MarketToken storage currentItem = idToNft[currentId];
                // Store the nft in the array
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        // Return the array
        return items;
    }

    // Function to get all nfts owned by the user
    function fetchMyNfts() public view returns (MarketToken[] memory) {
        // Total number of nfts in the market
        uint totalItemCount = _tokenIds.current();
        // Number of nfts owned by the user
        uint itemCount = 0;

        // Get the number of nfts owned by the user   
        for(uint i=1; i<=totalItemCount; i++) {
            if(idToNft[i].owner==msg.sender) {
                itemCount++;
            }
        }

        // Array to store the nfts owned by the user
        MarketToken[] memory items = new MarketToken[](itemCount);
        uint currentIndex = 0;

        // Loop starts from 1 because itemId starts from 1
        for(uint i=1; i<=totalItemCount; i++) {
            // Check if the nft is owned by the user
            if(idToNft[i].owner==msg.sender) {
                // Get the current nft from the database
                uint currentId = i;
                MarketToken storage currentItem = idToNft[currentId];
                // Store the nft in the array
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        // Return the array
        return items;
    }

    // Function to get all nfts minted by the user
    function fetchMintedNfts() public view returns (MarketToken[] memory) {
        // Total number of nfts in the market
        uint totalItemCount = _tokenIds.current();
        // Number of nfts minted by the user
        uint itemCount = 0;

        // Get the number of nfts minted by the user
        for(uint i=1; i<=totalItemCount; i++) {
            if(idToNft[i].seller==msg.sender) {
                itemCount++;
            }
        }

        // Array to store the nfts minted by the user
        MarketToken[] memory items = new MarketToken[](itemCount);
        uint currentIndex = 0;

        // Loop starts from 1 because itemId starts from 1
        for(uint i=1; i<=totalItemCount; i++) {
            // Check if the nft is minted by the user
            if(idToNft[i].seller==msg.sender) {
                // Get the current nft from the database
                uint currentId = i;
                MarketToken storage currentItem = idToNft[currentId];
                // Store the nft in the array
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        // Return the array
        return items;
    }
}
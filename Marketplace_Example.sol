// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AuctionFactory.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    uint256 public marketPlaceFee;
    
    address payable public authority;
    address public auctionFactory;

    constructor(address factory) {
        authority = payable(msg.sender);
        auctionFactory = factory;
    }

    struct Item {
        uint256 collectionId;
        uint256 itemId;
        uint256 price;
        address payable holder;
        bool listed;
    }

    struct Collection {
        uint256 collectionId;
        uint256 collectionSize;
        uint256 collectionRoyalty;
        mapping(uint256 => Item) collectionItem;
        string collectionName;
        address creator;
    }

    event itemListed(
        uint256 indexed itemId,
        uint256 indexed collectionId,
        uint256 price,
        address seller
    );

    event itemBought(
        uint256 indexed itemId,
        uint256 indexed collectionId,
        uint256 price,
        address seller,
        address buyer
    );

    event itemCanceled(
        uint256 indexed itemId,
        uint256 indexed collectionId,
        address seller
    );

    event itemCreated(
        uint256 indexed itemId,
        uint256 indexed collectionId,
        address creator
    );

    event collectionCreated(
        uint256 indexed collectionId,
        address creator,
        address collectionName
    );

    mapping(uint256 => Item) public items;
    mapping(uint256 => Collection) public collections;
    uint256 public itemCount; 
    uint256 public collectionCount; 

    function list(IERC721 _nft, uint256 _tokenId, uint256 _price, uint256 _collectionId) external {
        require(msg.sender == _nft.ownerOf(_tokenId), "You are not the owner of NFT");
        itemCount++;
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        items[itemCount] = Item(_collectionId, _tokenId, _price, payable(msg.sender), true);

        emit itemListed(
            itemCount,
            _collectionId,
            _price,
            msg.sender
        );
    }

    function cancelListing(IERC721 _nft, uint256 _tokenId, uint256 _collectionId) external {
        require(msg.sender == items[_tokenId].holder, "You are not the owner of NFT");
        require(items[_tokenId].listed, "Item is not listed");
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        items[itemCount] = Item(_collectionId, _tokenId, items[_tokenId].price, payable(msg.sender), false);

        emit itemCanceled(
            _tokenId,
            _collectionId,
            msg.sender
        );
    }

    function buy(IERC721 _nft, uint256 _tokenId, uint256 _collectionId) external payable {
        require(items[_tokenId].listed, "Item is not listed");
        require(msg.value == items[_tokenId].price, "Wrong price");
        items[_tokenId].holder.transfer(msg.value);
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        items[_tokenId].holder = payable(msg.sender);
        items[_tokenId].listed = false;

        emit itemBought(
            _tokenId,
            _collectionId,
            items[_tokenId].price,
            items[_tokenId].holder,
            msg.sender
        );
    }

    function setting(uint256 _newFee, address _newAuc) external onlyOwner {
        marketPlaceFee = _newFee;
        auctionFactory = _newAuc;
    }

    function createAuction() external nonReentrant {
        AuctionFactory auc = AuctionFactory(auctionFactory);
        auc.createAuction(marketPlaceFee);
    }

    

}


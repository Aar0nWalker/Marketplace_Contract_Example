// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction {
    event Start(address indexed holder);
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);

    address payable public seller;

    uint256 public marketPlaceFee;

    IERC721 public nft;
    uint256 public nftId;

    mapping(address => uint256) public userBids;

    bool started;
    bool ended;
    uint256 endAt;
    uint256 highestBid;
    address highestBidder;

    constructor(address _owner, uint256 _marketPlaceFee) {
        _owner = msg.sender;
        marketPlaceFee = _marketPlaceFee;
    }

    function start(IERC721 _nft, uint256 _nftId, uint256 startingBid, uint256 time) external {
        require(!started, "Already started!");
        require(msg.sender == seller, "You did not start the auction!");
        highestBid = startingBid;

        nft = _nft;
        nftId = _nftId;
        nft.transferFrom(msg.sender, address(this), nftId);

        started = true;
        endAt = block.timestamp + time;

        emit Start(msg.sender);
    }

    function bid() external payable {
        require(started, "Not started.");
        require(block.timestamp < endAt, "Ended!");
        require(msg.value > highestBid);

        if (highestBidder != address(0)) {
            userBids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(highestBidder, highestBid);
    }

    function withdraw() external payable {
        require(msg.sender != highestBidder);
        uint256 amount = userBids[msg.sender];
        userBids[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Could not withdraw");

        emit Withdraw(msg.sender, amount);
    }

    function end() external {
        require(started, "Auction is not started yet");
        require(block.timestamp >= endAt, "Auction is still ongoing!");
        require(!ended, "Auction already ended!");

        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            (bool sent, ) = seller.call{value: highestBid}("");
            require(sent, "Could not pay seller!");
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        ended = true;
        emit End(highestBidder, highestBid);
    }
}
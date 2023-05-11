// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Auction.sol";
contract AuctionFactory {

    Auction[] private _auctions;

    function createAuction(uint256 _marketPlaceFee) external {
        Auction auction = new Auction(msg.sender, _marketPlaceFee);
        _auctions.push(auction);
    }

    function getAuctions() public view returns (Auction[] memory) {
        return _auctions;
    }
}
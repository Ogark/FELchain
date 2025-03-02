// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AuctionFactory {
    function createAuction(address seller) external returns (address);
}

contract AuctionMain {
    address[] public auctions;
    address owner;
    address private eng;
    address private dut;
    address private seal;

    mapping (address => uint24) public rating;

    enum AuctionType { ENGLISH, DUTCH, SEALED }
    
    event AuctionCreated(address auctionAddress, address seller);

    constructor(address _eng, address _dut, address _seal) {
        owner = msg.sender;
        eng = _eng;
        dut = _dut;
        seal = _seal;
    }

    function changeAdresses(address _eng, address _dut, address _seal) public {
        require(owner == msg.sender, "Only owner");
        eng = _eng;
        dut = _dut;
        seal = _seal;
    }

    function createAuction(AuctionType _type) public payable returns (address) {
        require(msg.value > 0.001 ether, "Auction creation cost is 0.001 ETH");
        address auction;
        if (_type == AuctionType.ENGLISH) {
            auction = AuctionFactory(eng).createAuction(msg.sender);
        } else if (_type == AuctionType.DUTCH) {
            auction = AuctionFactory(dut).createAuction(msg.sender);
        } else {
            auction = AuctionFactory(seal).createAuction(msg.sender);
        }

        auctions.push(auction);
        emit AuctionCreated(auction, msg.sender);

        return address(auction);
    }

    function getAuctionCount() external view returns (uint256) {
        return auctions.length;
    }

    function withdraw() external {
        require(msg.sender == owner, "You are not the owner");    
        payable(owner).transfer(address(this).balance);
    }

    function isAuction() public view returns (bool) {
        for (uint i = 0; i < auctions.length; i++) {
            if (msg.sender == auctions[i]) {
                return true;
            }
        }
        return false;
    }

    function addRating(address _address) external  {
        require(isAuction(), "Only auction can change rating");
        rating[_address]++;
    }
}

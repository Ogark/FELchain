// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Main.sol";

contract SealedAuctionFactory {
    address owner;
    address main;
    
    event AuctionCreated(address auctionAddress, address seller);

    constructor() {
        owner = msg.sender;
    }

    function setMain(address _main) public {
        require(msg.sender == owner, "Only owner");
        main = _main;
    }

    function createAuction(address seller) public returns (address) {
        require(msg.sender == main);
        SealedAuction auction = new SealedAuction(main, seller);
        return address(auction);
    }
}


contract SealedAuction is ERC1155Receiver, ERC721Holder {
    address public seller;
    address public main;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public endBiddingTime;
    uint256 public endAuctionTime;
    bool public ended = false;
    bool public created = false;

    enum TokenType { INFO, ERC20, ERC721, ERC1155 }
    struct AuctionItem {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // Only for ERC-721 & ERC-1155
        uint256 amount;  // Only for ERC-20 & ERC-1155
        string info;
    }

    AuctionItem public auctionItem;
    mapping(address => uint256) public pendingReturns;

    event FirstBidRevealed();
    event AuctionEnded(address winner, uint256 amount);

    modifier iscreated() {
        require(created);
        _;
    }

    constructor(address _main, address _seller) {
        main = _main;
        seller = _seller;
    }

    function create(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        string memory _info,
        TokenType _tokenType,
        uint256 _minValue,
        uint256 _biddingTime,
        uint256 _revealTime
    ) external {
        require(!created, "Auction is already created");
        require(msg.sender == seller, "You are not auction owner");
        endBiddingTime = block.timestamp + _biddingTime;
        endAuctionTime = endBiddingTime + _revealTime;
        highestBid = _minValue;
        highestBidder = address(0);
        ended = false;

        auctionItem = AuctionItem({
            tokenType: _tokenType,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: _amount,
            info: _info
        });

        if (_tokenType == TokenType.ERC20) {
            require(
                IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
                "ERC20 transfer failed"
            );
        } else if (_tokenType == TokenType.ERC721) {
            IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        } else if (_tokenType == TokenType.ERC1155) {
            require(IERC1155(_tokenAddress).balanceOf( address(this), _tokenId) == _amount);
        }
        created = true;
    }

    mapping(address => bytes32) public bids;

    function placeBid(bytes32 _hashedBid) external {
        require(bids[msg.sender] == bytes32(0), "Bid already placed");
        require(block.timestamp < endBiddingTime, "Bidding finished");
        bids[msg.sender] = _hashedBid;
    }
    
    function generateHash(uint256 _value, string memory _pwd) pure external returns (bytes32){
        // ONLY FOR TESTINGG
        return keccak256(abi.encodePacked(_pwd, _value));
    }

    function revealBids(uint256 _value, string memory _pwd) payable external {
        require(block.timestamp >= endBiddingTime, "Bidding is not ended");
        require(block.timestamp < endAuctionTime, "Auction ended");
        require(_value > highestBid, "You don't need to reveal lower bid");
        require(keccak256(abi.encodePacked(_pwd, _value)) == bids[msg.sender], "Wrong data");
        require(_value <= msg.value, "Not enough funds");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        } else {
            emit FirstBidRevealed();
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external {
        require(block.timestamp >= endAuctionTime, "Auction not yet");
        require(!ended, "Auction already ended");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (highestBidder == address(0)) {
            highestBidder = seller;
        } else {
            AuctionMain(main).addRating(seller);
            payable(seller).transfer(highestBid - highestBid / 100);
            payable(main).transfer(address(this).balance);
        }


        if (auctionItem.tokenType == TokenType.ERC20) {
            require(
                IERC20(auctionItem.tokenAddress).transfer(highestBidder, auctionItem.amount),
                "ERC20 transfer failed"
            );
        } else if (auctionItem.tokenType == TokenType.ERC721) {
            IERC721(auctionItem.tokenAddress).approve(highestBidder, auctionItem.tokenId);
        } else if (auctionItem.tokenType == TokenType.ERC1155) {
            IERC1155(auctionItem.tokenAddress).safeTransferFrom(address(this), highestBidder, auctionItem.tokenId, auctionItem.amount, "");
        }
    }

    function onERC1155Received(
        address, address, uint256, uint256, bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, address, uint256[] calldata, uint256[] calldata, bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

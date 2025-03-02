// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Main.sol";

contract EnglishAuctionFactory {
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
        EnglishAuction auction = new EnglishAuction(main, seller);
        return address(auction);
    }

}

contract EnglishAuction is ERC1155Receiver, ERC721Holder, ReentrancyGuard {
    address public seller;
    address public main;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public highestBidTime;
    uint256 public minRaise;
    uint256 public bidWinTime;
    uint256 public endTime;
    bool public ended;
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

    event NewBid(address indexed bidder, uint256 amount);
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
        uint256 _startingValue,
        uint256 _minRaise,
        uint _bidWinTime,
        uint256 _biddingTime
    ) external nonReentrant{
        require(!created, "Auction is already created");
        require(msg.sender == seller, "You are not auction owner");
        endTime = block.timestamp + _biddingTime;
        highestBid = _startingValue;
        highestBidder = address(0);
        minRaise = _minRaise;
        bidWinTime = _bidWinTime;
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

    function bid() external payable iscreated nonReentrant {
        require((((block.timestamp < highestBidTime + bidWinTime) && (highestBidTime != 0)) || (highestBidder == address(0))
                        && block.timestamp < endTime), "Auction ended");
        require(msg.value > highestBid + minRaise, "Bid must be higher");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        highestBidTime = block.timestamp;

        emit NewBid(msg.sender, msg.value);
    }

    function withdraw() external iscreated nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external iscreated nonReentrant {
        require(
            ((block.timestamp >= highestBidTime + bidWinTime && highestBidTime != 0) ||
            (highestBidder == address(0))) ||
            (block.timestamp >= endTime),
            "Auction not yet ended"
        );
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

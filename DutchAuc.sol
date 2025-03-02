// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Main.sol";

contract DutchAuctionFactory {
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
        DutchAuction auction = new DutchAuction(main, seller);
        return address(auction);
    }
}

contract DutchAuction is ERC1155Receiver, ERC721Holder, ReentrancyGuard {
    address public seller;
    address public main;
    address public winner;
    uint256 public startPrice;
    uint256 public reservePrice;
    uint256 public startTime;
    uint256 public duration;
    uint256 public buyDuration;
    uint256 public priceDropRate; // Наскільки ціна зменшується за секунду
    bool public ended;
    bool public created = false;

    enum TokenType { INFO, ERC20, ERC721, ERC1155 }
    struct AuctionItem {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        string info;
    }

    AuctionItem public auctionItem;

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
        uint256 _startPrice,
        uint256 _reservePrice,
        uint256 _duration,
        uint256 _buyDuration
    ) payable external nonReentrant {
        require(!created, "Auction is already created");
        require(msg.sender == seller, "You are not auction owner");
        require(_startPrice > _reservePrice, "Start price must be higher than reserve price");
        startPrice = _startPrice;
        reservePrice = _reservePrice;
        duration = _duration;
        buyDuration = _buyDuration;
        startTime = block.timestamp;
        ended = false;
        priceDropRate = (startPrice - reservePrice) / duration;

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

    function getCurrentPrice() public view iscreated returns (uint256) {
        if (block.timestamp >= startTime + duration) {
            return reservePrice;
        }
        return startPrice - ((block.timestamp - startTime) * priceDropRate);
    }

    function buy() external payable iscreated nonReentrant {
        require(block.timestamp < startTime + buyDuration, "Auction has ended");
        require(!ended, "Auction has ended");
        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "Not enough funds");

        ended = true;
        winner = msg.sender;
        emit AuctionEnded(msg.sender, currentPrice);
        
        AuctionMain(main).addRating(seller);
        payable(seller).transfer(currentPrice - currentPrice / 100);
        payable(main).transfer(address(this).balance);

        if (auctionItem.tokenType == TokenType.ERC20) {
            require(
                IERC20(auctionItem.tokenAddress).transfer(winner, auctionItem.amount),
                "ERC20 transfer failed"
            );
        } else if (auctionItem.tokenType == TokenType.ERC721) {
            IERC721(auctionItem.tokenAddress).approve(winner, auctionItem.tokenId);
        } else if (auctionItem.tokenType == TokenType.ERC1155) {
            IERC1155(auctionItem.tokenAddress).safeTransferFrom(address(this), winner, auctionItem.tokenId, auctionItem.amount, "");
        }

        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }
    }

    function withdraw() public nonReentrant iscreated {
        require(block.timestamp >= startTime + buyDuration, "Auction is not yet");
        require(msg.sender == seller, "You are not seller");
        ended = true;
        if (auctionItem.tokenType == TokenType.ERC20) {
            require(
                IERC20(auctionItem.tokenAddress).transfer(seller, auctionItem.amount),
                "ERC20 transfer failed"
            );
        } else if (auctionItem.tokenType == TokenType.ERC721) {
            IERC721(auctionItem.tokenAddress).approve(seller, auctionItem.tokenId);
        } else if (auctionItem.tokenType == TokenType.ERC1155) {
            IERC1155(auctionItem.tokenAddress).safeTransferFrom(address(this), seller, auctionItem.tokenId, auctionItem.amount, "");
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

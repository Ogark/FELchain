# On-Chain Auction Marketplace

## Introduction
The **On-Chain Auction Marketplace** is a decentralized platform for secure and transparent auctions of digital and physical assets. It uses blockchain and smart contracts to ensure fair bidding, automated settlements, and verifiable ownership transfers.

## Features
- **On-Chain Transparency**: Immutable record of all auction activities.
- **Multiple Auction Types**: Supports English, Dutch, sealed-bid, and time-based auctions.
- **Smart Contract Automation**: Handles bidding, payments, and asset transfers without intermediaries.
- **Tokenized Assets**: Supports ERC-20, ERC-721, and ERC-1155 tokens for NFTs, tokens, and real-world assets.
- **Trustless Payments & Escrow**: Funds are securely held in smart contracts until auction completion.
- **Decentralized Identity & Reputation**: Trust system based on on-chain activity.
- **Interoperability**: Supports cross-chain asset auctions.
- **Web3 Wallet Integration**: Seamless participation via MetaMask or similar wallets.

## Smart Contracts
The platform consists of four Solidity smart contracts:

### **1. EnglishAuc.sol**
This file contains two contracts: **EnglishAuctionFactory** (factory for auctions) and **EnglishAuction** (auction logic).

#### **EnglishAuctionFactory Contract**
- **`constructor()`** – Sets the deployer as the **owner**.
- **`setMain(address _main)`** – Assigns the **main** contract (AuctionMain). Only callable by the **owner**.
- **`createAuction(address seller) returns (address)`** – Creates an **EnglishAuction** instance, callable only by **main**.

#### **EnglishAuction Contract**
- **`constructor(address _main, address _seller)`** – Initializes the auction, setting **main** and **seller**. Used by AuctionMain.
- **`create(...)`** – Starts an English auction, setting token details and pricing parameters. Called only by seller.  
  **Parameters:**
  - **`_tokenAddress`** (address): The address of the token (ERC-20, ERC-721, ERC-1155).
  - **`_tokenId`** (uint256): The ID of the token (only for ERC-721/ERC-1155).
  - **`_amount`** (uint256): The amount of tokens (only for ERC-20/ERC-1155).
  - **`_info`** (string): Additional information about the auctioned item.
  - **`_tokenType`** (0,1,2,3): Type of token being auctioned (Only info, ERC-20, ERC-721, ERC-1155).
  - **`_startingValue`** (uint256): The starting bid value for the auction.
  - **`_minRaise`** (uint256): The minimum raise required for each subsequent bid.
  - **`_bidWinTime`** (uint): The time (in seconds) until the auction ends after bid is placed.
  - **`_biddingTime`** (uint256): The total duration of the bidding phase in seconds.
  
- **`bid()`** – Places a bid, ensuring it exceeds the previous one by `minRaise`. Refunds the last highest bidder.

- **`withdraw()`** – Allows users to reclaim their pending refunds.

- **`endAuction()`** – Ends the auction, transfers the asset to the highest bidder, and pays the seller (minus a 1% fee).

- **`onERC1155Received(...)` & `onERC1155BatchReceived(...)`** – Handle ERC-1155 token transfers.

### 2. **DutchAuc.sol**
This file contains two contracts: **DutchAuctionFactory** (factory for auctions) and **DutchAuction** (auction logic).

#### **DutchAuctionFactory Contract**
- **`constructor()`** – Sets the deployer as the **owner**.
- **`setMain(address _main)`** – Assigns the **main** contract (AuctionMain). Only callable by the **owner**.
- **`createAuction(address seller) returns (address)`** – Creates a **DutchAuction** instance, callable only by **main**.

#### **DutchAuction Contract**

- **`constructor(address _main, address _seller)`**  
  Initializes the auction, setting **main** and **seller**. Used by AuctionMain.

- **`create(...)`**  
  Starts a Dutch auction, setting token details and pricing parameters. Called only by the seller.  
  **Parameters:**
  - **`_tokenAddress`** (address): The address of the token (ERC-20, ERC-721, ERC-1155).
  - **`_tokenId`** (uint256): The ID of the token (only for ERC-721/ERC-1155).
  - **`_amount`** (uint256): The amount of tokens (only for ERC-20/ERC-1155).
  - **`_info`** (string): Additional information about the auctioned item.
  - **`_tokenType`** (0,1,2,3): Type of token being auctioned (Only info, ERC-20, ERC-721, ERC-1155).
  - **`_startPrice`** (uint256): Auction start price.
  - **`_reservePrice`** (uint256): Reserve price.
  - **`_duration`** (uint256): Auction duration in seconds.
  - **`_buyDuration`** (uint256): Time until the auction closes (if longer than the duration - the opportunity to buy the item at the minimum price).

- **`getCurrentPrice()`**  
  Calculates the current auction price based on the elapsed time.

- **`buy()`**  
  Allows a buyer to purchase the asset at the current price. Ends the auction, transfers the asset, and distributes funds (1% fee to **main**).

- **`withdraw()`**  
  Lets the seller reclaim the asset if the auction ends without a sale.

- **`onERC1155Received(...)` & `onERC1155BatchReceived(...)`**  
  Handle ERC-1155 token transfers.

### 3. **SealedAuc.sol**
This file contains two contracts: **SealedAuctionFactory** (factory for auctions) and **SealedAuction** (auction logic).

#### **SealedAuctionFactory Contract**
- **`constructor()`** – Sets the deployer as the **owner**.
- **`setMain(address _main)`** – Assigns the **main** contract (AuctionMain). Only callable by the **owner**.
- **`createAuction(address seller) returns (address)`** – Creates a **SealedAuction** instance, callable only by **main**.

#### **SealedAuction Contract**
- **`constructor(address _main, address _seller)`** – Initializes the auction, setting **main** and **seller**. Used by AuctionMain.
- **`create(...)`** – Starts a Sealed auction, setting token details and pricing parameters. Called only by seller.  
  **Parameters:**
  - **`_tokenAddress`** (address): The address of the token (ERC-20, ERC-721, ERC-1155).
  - **`_tokenId`** (uint256): The ID of the token (only for ERC-721/ERC-1155).
  - **`_amount`** (uint256): The amount of tokens (only for ERC-20/ERC-1155).
  - **`_info`** (string): Additional information about the auctioned item.
  - **`_tokenType`** (0,1,2,3): Type of token being auctioned (Only info, ERC-20, ERC-721, ERC-1155).
  - **`_minValue`** (uint256): The minimum bid value for the auction.
  - **`_biddingTime`** (uint256): The total duration of the bidding phase in seconds.
  - **`_revealTime`** (uint256): The time (in seconds) allocated for revealing bids after the bidding phase ends.

- **`placeBid(bytes32 _hashedBid)`** – Allows users to place a bid by submitting a hashed value before the bidding period ends.

- **`generateHash(uint256 _value, string memory _pwd)`** – Generates a hash of the bid for testing purposes.

- **`revealBids(uint256 _value, string memory _pwd)`** – Reveals bids after the bidding period ends, ensuring the bid is correct and higher than the previous highest.

- **`withdraw()`** – Lets bidders withdraw their funds if they are outbid.

- **`endAuction()`** – Ends the auction after the reveal period, transfers the asset to the highest bidder, and disburses the funds (1% fee to **main**).

- **`onERC1155Received(...)` & `onERC1155BatchReceived(...)`** – Handle ERC-1155 token transfers.

### 4. **Main.sol**
This file contains the **Main** contract, which handles the creation and management of auctions.

#### **Constructor**
- **`constructor(address _eng, address _dut, address _seal)`** – Initializes the contract by setting the **owner** and the factory addresses for English (eng), Dutch (dut), and Sealed (seal) auctions.

#### **Functions**
- **`changeAdresses(address _eng, address _dut, address _seal)`** – Changes factories adresses. Only owner.
- **`createAuction(AuctionType _type) public payable returns (address)`** – Creates a new auction of the specified type (English, Dutch, or Sealed). Stores the auction address in the `auctions` array and returns the auction address. Requires a minimum fee of 0.001 ETH.
- **`getAuctionCount() external view returns (uint256)`** – Returns the total number of created auctions.
- **`withdraw()` external** – Allows only the contract owner to withdraw all funds from the contract.
- **`isAuction() public view returns (bool)`** – Checks if the caller (**msg.sender**) is one of the created auctions.
- **`addRating(address _address) external`** – Increases the rating of a user (stored in `rating[_address]`). This function can only be called by an auction contract.
- **`auctions(uint256 index) public view returns (address)`** – Retrieves the address of an auction at a given index in the `auctions` array.
- **`rating(address user) public view returns (uint24)`** – Returns the rating of a specific user.


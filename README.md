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
- **`constructor(address _main, address _seller)`** – Initializes the auction, setting **main** and **seller**.
- **`create(...)`** – Creates an auction, transfers assets, and sets bidding parameters.
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
- **`constructor(address _main, address _seller)`** – Initializes the auction, setting **main** and **seller**.
- **`create(...)`** – Starts a Dutch auction, setting token details and pricing parameters.
- **`getCurrentPrice()`** – Calculates the current auction price based on elapsed time.
- **`buy()`** – Allows a buyer to purchase the asset at the current price. Ends the auction, transfers the asset, and distributes funds (1% fee to **main**).
- **`withdraw()`** – Lets the seller reclaim the asset if the auction ends without a sale.
- **`onERC1155Received(...)` & `onERC1155BatchReceived(...)`** – Handle ERC-1155 token transfers.

### 3. **SealedAuc.sol**
This file contains two contracts: **SealedAuctionFactory** (factory for auctions) and **SealedAuction** (auction logic).

#### **SealedAuctionFactory Contract**
- **`constructor()`** – Sets the deployer as the **owner**.
- **`setMain(address _main)`** – Assigns the **main** contract (AuctionMain). Only callable by the **owner**.
- **`createAuction(address seller) returns (address)`** – Creates a **SealedAuction** instance, callable only by **main**.

#### **SealedAuction Contract**
- **`constructor(address _main, address _seller)`** – Initializes the auction, setting **main** and **seller**.
- **`create(...)`** – Starts a sealed auction with bidding and reveal periods, setting token details and pricing parameters.
- **`placeBid(bytes32 _hashedBid)`** – Allows users to place a bid by submitting a hashed value before the bidding period ends.
- **`generateHash(uint256 _value, string memory _pwd)`** – Generates a hash of the bid for testing purposes.
- **`revealBids(uint256 _value, string memory _pwd)`** – Reveals bids after the bidding period ends, ensuring the bid is correct and higher than the previous highest.
- **`withdraw()`** – Lets bidders withdraw their funds if they are outbid.
- **`endAuction()`** – Ends the auction after the reveal period, transfers the asset to the highest bidder, and disburses the funds (1% fee to **main**).
- **`onERC1155Received(...)` & `onERC1155BatchReceived(...)`** – Handle ERC-1155 token transfers.

### 4. **Main.sol**
#### Constructor 
`constructor(address _eng, address _dut, address _seal)`
- Initializes the contract, setting the **owner** and the **factory addresses** for English (`eng`), Dutch (`dut`) and Sealed (`seal`) auctions.

#### Functions

`createAuction(AuctionType _type) public payable returns (address)`
- Creates a new auction of the selected type (**English, Dutch, or Sealed**).
- Stores the auction address in `auctions` and returns it.
- Requires a minimum fee of **0.001 ETH**.

`getAuctionCount() external view returns (uint256)`
- Returns the total number of created auctions.

`withdraw() external`
- Allows only the **contract owner** to withdraw all funds from the contract.

`isAuction() public view returns (bool)`
- Checks if `msg.sender` is one of the created auctions.

`addRating(address _address) external`
- Increases the **rating** of a user (`rating[_address]`).
- Can only be called by an auction.

`auctions(uint256 index) public view returns (address)`
- Allows retrieving the address of an auction at a given `index` in the `auctions` array.

`rating(address user) public view returns (uint24)`
- Returns the **rating** of a specific `user`.

## About Solidity
**Solidity** is a statically typed programming language designed for writing smart contracts on Ethereum and compatible blockchains. It enables automation and trustless execution of agreements using the Ethereum Virtual Machine (EVM). 

## Setup
### Prerequisites
- Node.js & npm
- Hardhat or Truffle
- Solidity Compiler (0.8.x)
- Web3 Wallet (MetaMask)

### Installation
1. Clone the repository:
   ```sh
   git clone [https://github.com/Ogark/FELchain/tree/main]
   ```
2. Install dependencies:
   ```sh
   npm install
   ```
3. Compile and deploy smart contracts:
   ```sh
   npx hardhat compile
   npx hardhat run scripts/deploy.js --network goerli
   ```

## Usage
- Connect your Web3 wallet.
- Create and manage auctions.
- Place bids and track auction results.
- Funds are securely transferred upon auction completion.



## Example

A "Hello World" program in Solidity is of even less use than in other languages, but still:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract HelloWorld {
    function helloWorld() external pure returns (string memory) {
        return "Hello, World!";
    }
}
```
і

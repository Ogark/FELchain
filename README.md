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

### 1. **EnglishAuc.sol**
- This file implements 2 smart contracts, 1 contract is the implementation of the auction and the factory contract.

#### **EnglishAuctionFactory Contract**

##### **`constructor()`**
- Initializes the contract and sets the deployer as the **owner**.

#### **`setMain(address _main) public`**
- Sets the **main** contract address (AuctionMain).
- Can only be called by the **owner**.

##### **`createAuction(address seller) public returns (address)`**
- Creates a new **EnglishAuction** contract.
- Can only be called by the **main** contract.
- Returns the address of the newly created auction.

### **EnglishAuction Contract**

##### **`constructor(address _main, address _seller)`**
- Initializes an auction contract, setting:
  - The **main** auction contract (`_main`).
  - The **seller** (`_seller`).

##### **`create(...) external nonReentrant`**
- Creates a new auction with the provided parameters:
  - **Token details**: Address, ID, Amount, Info, Token Type.
  - **Auction parameters**: Starting bid, Minimum bid increment, Bid win time, Duration.
- Transfers the auctioned asset to the contract.

##### **`bid() external payable iscreated nonReentrant`**
- Allows users to place a bid.
- Ensures:
  - The auction is still active.
  - The new bid is higher than the previous bid by at least `minRaise`.
- Refunds the previous highest bidder.

##### **`withdraw() external iscreated nonReentrant`**
- Allows users to withdraw their refundable bid amounts.
- Ensures that the caller has pending returns.

### **`endAuction() external iscreated nonReentrant`**
- Ends the auction if:
  - The auction time has expired.
  - The highest bid is held for `bidWinTime`.
- Transfers the winning bid amount to the seller (minus 1% fee to `main` contract).
- Transfers the auctioned asset to the highest bidder.

##### **`onERC1155Received(...) external pure override returns (bytes4)`**
- Implements ERC-1155 receiver interface.

##### **`onERC1155BatchReceived(...) external pure override returns (bytes4)`**
- Implements ERC-1155 batch receiver interface.


### 2. **DutchAuc.sol**
- ????????????????????.

### 3. **SealedAuc.sol**
- ???????????????????.

### 4. **Main.sol**
#### Constructor 
##### `constructor(address _eng, address _dut, address _seal)`
- Initializes the contract, setting the **owner** and the **factory addresses** for English (`eng`), Dutch (`dut`) and Sealed (`seal`) auctions.

#### Functions

##### `createAuction(AuctionType _type) public payable returns (address)`
- Creates a new auction of the selected type (**English, Dutch, or Sealed**).
- Stores the auction address in `auctions` and returns it.
- Requires a minimum fee of **0.001 ETH**.

##### `getAuctionCount() external view returns (uint256)`
- Returns the total number of created auctions.

##### `withdraw() external`
- Allows only the **contract owner** to withdraw all funds from the contract.

##### `isAuction() public view returns (bool)`
- Checks if `msg.sender` is one of the created auctions.

##### `addRating(address _address) external`
- Increases the **rating** of a user (`rating[_address]`).
- Can only be called by an auction.

##### `auctions(uint256 index) public view returns (address)`
- Allows retrieving the address of an auction at a given `index` in the `auctions` array.

##### `rating(address user) public view returns (uint24)`
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

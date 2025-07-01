# Decentralized Escrow Smart Contract

![Solidity](https://img.shields.io/badge/Solidity-0.8.18-blue)
![Foundry](https://img.shields.io/badge/Foundry-black?style=flat&logo=foundry&logoColor=white)
![Chainlink](https://img.shields.io/badge/Chainlink-375BD2?style=flat&logo=chainlink&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 💡 Overview

This repository features a robust and secure **decentralized escrow smart contract** built on the Ethereum Virtual Machine (EVM). It serves as a neutral, trusted third party, holding funds securely until predefined conditions are met by transacting parties. This eliminates the need for traditional intermediaries, offering a transparent and immutable solution for peer-to-peer exchanges.

The project leverages **Chainlink Price Feeds** to ensure that deposited amounts meet a minimum USD equivalent, mitigating cryptocurrency price volatility risks. Developed with the **Foundry** toolchain, it emphasizes gas efficiency, clear state management, and comprehensive testing.

---

## ✨ Features

* **Secure Funds Holding:** Safely locks deposited Ether within the contract until transaction conditions are fulfilled.
* **Buyer & Seller Roles:** Clearly defines and enforces access control for the `owner` (seller) and `buyer` participants.
* **Delivery Confirmation:** Allows the seller to confirm the successful delivery of the asset, enabling fund release.
* **Buyer Refund Mechanism:** Enables the buyer to request a refund, returning the deposited funds if delivery is not confirmed within the agreed terms.
* **Dispute Resolution Path:** Provides a mechanism for either party to initiate a dispute, signaling a need for external arbitration if a disagreement arises.
* **Chainlink Price Feed Integration:** Utilizes Chainlink's `ETH/USD` decentralized price feed to ensure deposit amounts meet a `[e.g., $5 USD]` minimum equivalent, protecting against price fluctuations.
* **Gas Optimized:** Engineered for efficiency, incorporating Solidity's custom errors for gas-saving reverts, `immutable` and `constant` state variables, and efficient data handling.
* **Foundry Toolchain:** Developed and rigorously tested using Forge, Anvil, and Cast, enabling a fast, reliable, and Solidity-native development workflow.

---

## 🛠️ Technologies Used

* **Solidity** (`^0.8.18`): The primary language for smart contract development.
* **Foundry:** A complete, blazing-fast, and highly modular toolkit for Ethereum application development.
    * **Forge:** Ethereum testing framework and development environment.
    * **Anvil:** Local Ethereum node for rapid testing and development.
    * **Cast:** Command-line tool for interacting with EVM smart contracts and data.
* **Chainlink:** Decentralized oracle network for real-world data; specifically, `AggregatorV3Interface` for secure price feeds.
* **EVM (Ethereum Virtual Machine):** The runtime environment for smart contracts on Ethereum and compatible blockchains.

---

## 🚀 Getting Started

Follow these steps to set up the project locally for development and testing.

### Prerequisites

* **Git:** [Download & Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* **Foundry:** Install Foundry by following the official documentation.
    ```bash
    curl -L [https://foundry.paradigm.xyz](https://foundry.paradigm.xyz) | bash
    foundryup # Installs the latest Foundry toolchain
    ```
    *(You may need to `source ~/.bashrc` or `~/.zshrc` after installation for `forge`, `cast`, and `anvil` commands to be available in your PATH.)*

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/](https://github.com/)[YOUR_GITHUB_USERNAME]/Decentralized-Escrow-Contract.git
    cd Decentralized-Escrow-Contract
    ```
    *Replace `[YOUR_GITHUB_USERNAME]` with your actual GitHub username.*

2.  **Install project dependencies:**
    This project relies on Chainlink contracts, which are installed as a Forge dependency.
    ```bash
    forge install smartcontractkit/chainlink@latest --no-commit
    ```

3.  **Build the project:**
    Compile the smart contracts. Any compilation errors will be shown here.
    ```bash
    forge build
    ```

---

## 🧪 Testing

This project leverages Foundry's robust testing framework (Forge) for both unit and integration tests.

### Local Unit Tests

Run all unit tests, which do not require a live network connection and use Foundry's powerful cheatcodes for state manipulation.

```bash
forge test

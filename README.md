# 🌱 DeFi Rebase Token

A decentralized protocol implementing a cross-chain rebase token (RBT) that incentivizes users to deposit into a vault and gain interest in rewards. The token automatically rebases based on time and interest rates, with each user maintaining their own interest rate from the time of deposit. The project includes cross-chain bridging capabilities using Chainlink's Cross-Chain Interoperability Protocol (CCIP). The project is built in Solidity and uses Foundry for automatic deployment and testing.

### Credit 🙏
This project is part of a code-along from the [Foundry Fundamentals](https://updraft.cyfrin.io/courses/foundry) course by [Cyfrin](https://cyfrin.io/). Big thanks for Patrick Collins and his team for offering free web3 education.

---

## ✨ Features

- **Rebase Token**: RBT automatically accrues interest over time.
- **Cross-Chain Support**: Seamless token bridging between different blockchain networks.
- **Individual Interest Rates**: Each user maintains their own interest rate.
- **Decreasing Interest Rate Policy**: Global interest rate can only decrease.
- **Vault Integration**: Users deposit ETH to receive rebase tokens.
- **Role-Based Access Control**: Only authorized contracts can mint and burn tokens.
- **Developer Workflow**: Lightning-fast testing, scripting, and deployment.
- **Fuzzing**: Includes Foundry's fuzzing tests for security.

---

## 📚 Tech Stack

| Tool                   | Purpose                              |
|------------------------|--------------------------------------|
| Solidity               | Smart contract language              |
| Foundry                | Compilation, testing, scripting      |
| Chainlink CCIP         | Cross-chain token bridging           |
| OpenZeppelin Contracts | Secure ERC20, AccessControl, Ownable |
| Sepolia Testnet        | Live test environment                |
| Makefile               | Streamlined local commands           |

---

## 🚀 Getting Started
Follow these steps to clone, install, and test the project locally or on testnets.

### 1. Prerequisites 🧰
You need to have Git and Foundry installed. Then clone the repository.

```shell
$ git clone https://github.com/dmaurex/defi-rebase-token.git
$ cd defi-rebase-token
```

### 2. Environment Setup 🔐
To run tests or deploy on testnets, create a `.env` file and set the following variables:
```
ETH_SEPOLIA_RPC_URL=...
ARB_SEPOLIA_RPC_URL=...
ETH_SEPOLIA_KEYSTORE=...
ARB_SEPOLIA_KEYSTORE=...
ETHERSCAN_API_KEY=...
```

### 3. Building 🛠️
Install dependencies and build the contracts:

```shell
$ make build
```

### 4. Run Tests 📝
Run test suites:

```shell
$ make test  # run ALL tests
$ make testLocal  # only unit and fuzz tests
$ make testFork  # only fork tests on Ethereum and Arbitrum Sepolia testnets (requires RPC URLs)
```

---

## 🌐 Deployment

### **Single Chain Functionality** 🏝️
For basic rebase token functionality on Ethereum Sepolia:

```shell
$ make deployEth
```

This deploys:
- **RebaseToken** - The rebase token contract
- **RebaseTokenPool** - CCIP pool for cross-chain bridging (not needed for single chain functionality)
- **Vault** - Contract for ETH deposits and RBT minting

### **Cross-Chain Functionality** 🌉
To enable cross-chain token bridging, deploy the rebase token and pool on Arbitrum Sepolia:

```shell
$ make deployArb
$ make confPools \
  ETH_SEPOLIA_REBASE_TOKEN_ADDRESS=0x...
  ARB_SEPOLIA_REBASE_TOKEN_ADDRESS=0x...
  ETH_SEPOLIA_POOL_ADDRESS=0x... \
  ARB_SEPOLIA_POOL_ADDRESS=0x... \
```

This deploys:
- **RebaseToken** - Same token contract on Arbitrum Sepolia
- **RebaseTokenPool** - CCIP pool for cross-chain bridging
- **Pool Configuration** - Links the pools from source chain (Ethereum Sepolia) and destination chain (Arbitrum Sepolia)

**Note**: The Vault is only needed on one chain (Ethereum Sepolia) since users deposit ETH there to mint RBT tokens.

---

## 🏦 Usage
Once the rebase token, pool, and vault contracts are deployed, users can interact with the protocol through the following functions.

### Vault Operations 💰
* `deposit()`: Deposit ETH to the vault and receive rebase tokens (RBT) in return. The amount of RBT received equals the ETH deposited, and these tokens will start accruing interest immediately.
* `redeem(uint256 amount)`: Redeem ETH from the vault by burning your RBT tokens. You can specify `type(uint256).max` to redeem all your tokens.

### Rebase Token Features 🌱
* **Automatic Interest Accrual**: RBT tokens automatically grow in value over time based on the user's individual interest rate
* **Individual Interest Rates**: Each user maintains their own interest rate from the time of deposit, protecting them from future rate decreases
* **Principal Balance**: Users can check their principal balance (without accrued interest) using `principalBalanceOf(address user)`
* **Current Balance**: Users can check their current balance (including accrued interest) using `balanceOf(address user)`

### Cross-Chain Bridging 🌉
* **Bridge Tokens**: Users can bridge their RBT tokens between different blockchain networks (e.g., Ethereum Sepolia to Arbitrum Sepolia). Cross-chain transfers require LINK tokens as network fee. The destination chain (e.g., Arbitrum Sepolia) requires a deployed rebase token and configured pool contract. However, the vault is only on the source chain (Ethereum Sepolia). To bridge tokens from Ethereum Sepolia to Arbitrum Sepolia use:

```shell
make bridgeEthToArb \
  RECEIVER= \  # Destination address on the target chain
  TOKEN= \  # RBT token contract address on source chain
  AMOUNT= \  # Amount of tokens to bridge (in wei)
```

* **Interest Rate Preservation**: When bridging, the user's interest rate is preserved across chains
* **Seamless Integration**: The bridging process automatically handles interest accrual and token minting/burning

### Administrative Functions ⚙️
* `grantMintAndBurnRole(address account)`: Grant minting and burning permissions to vault contracts (owner only)
* `setInterestRate(uint256 newInterestRate)`: Decrease the global interest rate (owner only, can only decrease)

---

## 📂 Project Structure
The repository follows the usual Foundry folder structure:

```shell
.
├── lib/ — "External libraries"
├── script/
│   ├── BridgeTokens.s.sol — "Token bridging script"
│   ├── ConfigurePool.s.sol — "Pool configuration script"
│   └── Deployer.s.sol — "Deployment scripts"
├── src/
│   ├── interfaces/
│   │   └── IRebaseToken.sol — "Interface for rebase token"
│   ├── RebaseToken.sol — "Main rebase token contract"
│   ├── RebaseTokenPool.sol — "CCIP pool for cross-chain token bridging"
│   └── Vault.sol — "Vault contract for ETH deposits and RBT minting"
├── test/
│   ├── mocks/ — "Mocks for testing"
│   ├── RebaseToken.t.sol — "Unit tests for rebase token functionality"
│   └── CrossChain.t.sol — "Cross-chain fork tests"
```


## 📜 License
This project is licensed under the **MIT License**. See the [LICENSE](./LICENSE) file for more details.

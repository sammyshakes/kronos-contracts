# Kronos Smart Contract Repository

## Installation

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) must be installed locally

1. Clone the repository containing the contract source code and deployment script:

   ```
   git clone git@github.com:kr0nos-bot/kronos-contracts.git
   cd kronos-contracts
   ```

2. Install dependencies:

   ```
   forge install
   ```

## Contract Testing

### To run the tests:

```bash
## without traces
forge test

#with traces
forge test --vvvv
```

---

---

# KronosSeedSale - DROP SOP

Standard operating procedure for deploying the KronosSeedSale contract

## Deployment of `KronosMultiSig.sol` and `KronosSeedSale.sol` :

## Prerequisites

- Funded Ethereum account (Deployer)
- Etherscan API key
- RPC URL (Mainnet)

### MultiSig Wallet

- Multisig owner addresses
- Multisig required confirmation address
- Multisig Number of confirmations required - currently: (3)

### SeedSale Contract

- USDT and USDC contract addresses
- Base URI for Kronos NFTs
- Multisig address (once deployed)

```r

# Deployment environment variables
MAINNET_RPC_URL=
ETHERSCAN_API_KEY=
DEPLOYER_ADDRESS=
DEPLOYER_PRIVATE_KEY=

# Constructor arguments for KronosSeedSale
# mainnet USDT and USDC contract addresses
USDT_CONTRACT_ADDRESS=0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC_CONTRACT_ADDRESS=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

# Multi-sig address (once deployed)
KRONOS_MULTISIG_ADDRESS=

# Base URI for Kronos NFTs
KRONOS_BASE_URI="ipfs://QmQZFPfNCtfd92icLPuHVdCFfCRWTQp2KSz6Wm8wTvRXoE/"
```

## Deployment of `KronosMultiSig.sol`

- Set the addresses of the owners.
- Set the required confirmation address.
- Set the number of comfirmations required for successful Tx.
- Run the script:

```bash
forge script script/DeployMultisig.s.sol:DeployMultisig -vvvv --rpc-url mainnet --broadcast --verify
```

- Set the Multisig wallet address into the `.env` file:

```r
KRONOS_MULTISIG_ADDRESS=
```

## Deployment of `KronosSeedSale.sol`

### 3. Set the following environment variables:

- `DEPLOYER_PRIVATE_KEY` - Private key of the deployer account
- `USDT_CONTRACT_ADDRESS` - USDT token address on Mainnet
- `USDC_CONTRACT_ADDRESS` - USDC token address on Mainnet
- `KRONOS_MULTISIG_ADDRESS` - Address to which USDT and USDC will be transferred
- `KRONOS_BASE_URI` - Base URI for Kronos NFTs

### 4. Run the `DeploySeedSale.s.sol` script:

```bash
forge script script/DeploySeedSale.s.sol:DeploySeedSale -vvvv --rpc-url mainnet --broadcast --verify
```

This will:

- Compile the contracts
- Deploy KronosSeedSale with USDT and USDC addresses
- Set the withdrawal address for USDT and USDC
- Set the base URI for Kronos NFTs
- Broadcast the transaction
- Verify the source code on Etherscan

### 5. The deployed contract address will be output. Visually confirm the deployment on Etherscan explorer.

- Set the contract address into the `.env` file:

```r
KRONOS_CONTRACT_ADDRESS=
```

### 6. Add the contract address to the `KronosMultiSig.sol` contract.

- Set the contract address in the `AddSeedSaleToMultisig.s.sol` script.
- Run the script:

```bash
forge script script/AddSeedSaleToMultisig.s.sol:AddSeedSaleToMultisig -vvvv --rpc-url mainnet --broadcast
```

### 7. Add Admins to the `KronosSeedSale.sol` contract.

- Set the contract addresses in the `AddAdminToSeedSale.s.sol` script.
- Run the script:

```bash
forge script script/AddAdminToSeedSale.s.sol:AddAdminToSeedSale -vvvv --rpc-url mainnet --broadcast
```

### 8. Run `AddToWhitelist.s.sol` script to add addresses to whitelist.

- Set the addresses to be added to the whitelist in the `AddToWhitelist.s.sol` script.
- Set metadata Id for the addresses to be added in the `AddToWhitelist.s.sol` script.
- Run the script:

```bash
forge script script/AddToWhitelist.s.sol:AddToWhitelist -vvvv --rpc-url mainnet --broadcast
```

### 9. Call `flipSeedSaleActive()` on the deployed contract to activate the sale.

```bash
forge script script/FlipSeedSaleActive.s.sol:FlipSeedSaleActive -vvvv --rpc-url mainnet --broadcast
```

### 10. Call `flipSeedSaleActive()` on the deployed contract to deactivate the sale.

```bash
forge script script/FlipSeedSaleActive.s.sol:FlipSeedSaleActive -vvvv --rpc-url mainnet --broadcast
```

### 11. Withdraw USDT and USDC from the contract.

> Note: Withdrawals must be executed from `KronosMultiSig.sol` contract.

- Execute the `withdrawTokensFromKronosSeedSale()` function on the `KronosMultiSig.sol` contract.

- Input the contract address for USDT or USDC. (value can be retrieved from `KronosSeedSale` contract)

### 12. Check balances of the `KronosMultiSig.sol` contract.

Navigate to USDT and USDC contracts on Etherscan and check the balance of the `KronosMultiSig.sol` contract address.

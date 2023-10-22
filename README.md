# KronosSeedSale - DROP SOP

Standard operating procedure for deploying the KronosSeedSale contract

## Deploying `KronosSeedSale.sol` :

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) installed locally
- Funded Ethereum account (Deployer)
- Etherscan API key
- RPC URL (Mainnet)
- USDT and USDC contract addresses
- Base URI for Kronos NFTs

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

# Base URI for Kronos NFTs
KRONOS_BASE_URI=
```

## Steps

1. Clone the repository containing the contract source code and deployment script:

   ```
   git clone <repo_url>
   cd kronos-contracts
   ```

2. Install dependencies:

   ```
   forge install
   ```

3. Set the following environment variables:

   - `DEPLOYER_PRIVATE_KEY` - Private key of the deployer account
   - `USDT_CONTRACT_ADDRESS` - USDT token address on Mainnet
   - `USDC_CONTRACT_ADDRESS` - USDC token address on Mainnet
   - `KRONOS_BASE_URI` - Base URI for Kronos NFTs

4. Run the deploy script:

   ```bash
   forge script script/DeploySeedSale.s.sol:DeploySeedSale -vvvv --rpc-url mainnet --broadcast --verify
   ```

   This will:

   - Compile the contracts
   - Deploy KronosSeedSale with USDT and USDC addresses
   - Set the base URI for Kronos NFTs
   - Broadcast the transaction
   - Verify the source code on Etherscan

5. The deployed contract address will be output. Visually confirm the deployment on Etherscan explorer.

   - Set the contract address into the `.env` file:

   ```r
   KRONOS_CONTRACT_ADDRESS=
   ```

6. Call `flipSeedSaleActive()` on the deployed contract to activate the sale.

```r
forge script script/FlipSeedSaleActive.s.sol:FlipSeedSaleActive -vvvv --rpc-url mainnet --broadcast
```

7. Call `flipSeedSaleActive()` on the deployed contract to deactivate the sale.

```r
forge script script/FlipSeedSaleActive.s.sol:FlipSeedSaleActive -vvvv --rpc-url mainnet --broadcast
```

# IKronosSeedSale
[Git Source](https://github.com/sammyshakes/kronos-contracts/blob/a868f3b7fb656eca4a74796777cd8445607a8c17/src/interfaces/IKronosSeedSale.sol)


## Functions
### flipSeedSaleActive


```solidity
function flipSeedSaleActive() external;
```

### addToWhitelist


```solidity
function addToWhitelist(address[] calldata wallets, uint256 metadataId) external;
```

### payWithUSDT


```solidity
function payWithUSDT(uint256 amount) external;
```

### payWithUSDC


```solidity
function payWithUSDC(uint256 amount) external;
```

### mint


```solidity
function mint() external;
```

### setBaseURI


```solidity
function setBaseURI(string calldata newURI) external;
```

### tokenURI


```solidity
function tokenURI(uint256 tokenID) external view returns (string memory);
```

### withdrawTokens


```solidity
function withdrawTokens(address token) external;
```

### seedSaleActive


```solidity
function seedSaleActive() external view returns (bool);
```

### USDT


```solidity
function USDT() external view returns (address);
```

### USDC


```solidity
function USDC() external view returns (address);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### totalUSDTokenAmountCommitted


```solidity
function totalUSDTokenAmountCommitted() external view returns (uint256);
```

### USDTokenAmountCommitted


```solidity
function USDTokenAmountCommitted(address user) external view returns (uint256);
```

### tokenIdToMetadataId


```solidity
function tokenIdToMetadataId(uint256 tokenId) external view returns (uint256);
```

### metaIDForAddress


```solidity
function metaIDForAddress(address user) external view returns (uint256);
```

## Events
### Payment

```solidity
event Payment(address from, uint256 amount, bool USDT);
```


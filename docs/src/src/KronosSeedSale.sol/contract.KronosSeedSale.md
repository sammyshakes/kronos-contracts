# KronosSeedSale
[Git Source](https://github.com/sammyshakes/kronos-contracts/blob/a868f3b7fb656eca4a74796777cd8445607a8c17/src/KronosSeedSale.sol)

**Inherits:**
Owned, ERC721

This contract is used to participate in the Kronos Seed Sale


## State Variables
### MINIMUM_PAYMENT

```solidity
uint256 public constant MINIMUM_PAYMENT = 250e6;
```


### MAXIMUM_TOTAL_PAYMENT

```solidity
uint256 public constant MAXIMUM_TOTAL_PAYMENT = 5000e6;
```


### MAXIMUM_RAISE

```solidity
uint256 public constant MAXIMUM_RAISE = 250_000e6;
```


### seedSaleActive

```solidity
bool public seedSaleActive;
```


### USDT

```solidity
address public USDT;
```


### USDC

```solidity
address public USDC;
```


### withdrawAddress

```solidity
address public immutable withdrawAddress;
```


### baseURI

```solidity
string public baseURI;
```


### totalSupply

```solidity
uint256 public totalSupply;
```


### totalUSDTokenAmountCommitted

```solidity
uint256 public totalUSDTokenAmountCommitted;
```


### USDTokenAmountCommitted

```solidity
mapping(address => uint256) public USDTokenAmountCommitted;
```


### tokenIdToMetadataId

```solidity
mapping(uint256 => uint256) public tokenIdToMetadataId;
```


### metaIDForAddress

```solidity
mapping(address => uint256) public metaIDForAddress;
```


### _admins

```solidity
mapping(address => bool) private _admins;
```


## Functions
### constructor

Constructor


```solidity
constructor(address _USDT, address _USDC, address _withdraw, string memory _baseURI)
    ERC721("Kronos Titans", "TITAN")
    Owned(msg.sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_USDT`|`address`|The address of the USDT contract|
|`_USDC`|`address`|The address of the USDC contract|
|`_withdraw`|`address`||
|`_baseURI`|`string`|The base URI for the token metadata|


### flipSeedSaleActive

Flip the seed sale active state

*Only the owner can call this function*


```solidity
function flipSeedSaleActive() external onlyOwner;
```

### addToWhitelist

Add addresses to the whitelist

*The metadata id is the id of the metadata json file that will be used for the token uri*

*Only admins can call this function*


```solidity
function addToWhitelist(address[] calldata wallets, uint256 metadataId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`wallets`|`address[]`|The addresses to add to the whitelist|
|`metadataId`|`uint256`|The metadata id to assign to these address|


### isWhitelisted

Check if an address is whitelisted

*An address is whitelisted if it has a metadata id or has made a payment*


```solidity
function isWhitelisted(address wallet) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`wallet`|`address`|The address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is whitelisted, false otherwise|


### payWithUSDT

Participate in the seed sale with USDT, if whitelisted

*requirements are checked in _payWithToken*


```solidity
function payWithUSDT(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of USDT to commit|


### payWithUSDC

Participate in the seed sale with USDC, if whitelisted

*requirements are checked in _payWithToken*


```solidity
function payWithUSDC(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of USDC to commit|


### _payWithToken

Participate in the seed sale with USDT or USDC, if whitelisted

*The amount must be a minimum of USD $250*

*The total amount must not exceed USD $5000*

*The total amount must not exceed USD $250,000*

*This function is called by payWithUSDT and payWithUSDC*


```solidity
function _payWithToken(address token, uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to commit|
|`amount`|`uint256`|The amount of tokens to commit|


### mint

Mint an NFT, if whitelisted

*The address must have made a minimum payment of USD $250*


```solidity
function mint() external;
```

### setBaseURI

Set the base URI

*Only the owner can call this function*


```solidity
function setBaseURI(string calldata newURI) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newURI`|`string`|The new base URI|


### tokenURI

Get the URI for a token

*The URI is the base URI + the metadata id*

*The metadata id is the id of the metadata json file that will be used for the token id*


```solidity
function tokenURI(uint256 tokenID) public view override returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenID`|`uint256`|The id of the token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The URI for the token|


### withdrawTokens

Withdraw tokens from the contract

*Only the owner can call this function*


```solidity
function withdrawTokens(address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to withdraw|


### addAdmins

Adds multiple admins to the contract.


```solidity
function addAdmins(address[] calldata admins) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admins`|`address[]`|The addresses of the new admins.|


### removeAdmin

Removes an admin from the contract.


```solidity
function removeAdmin(address admin) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The address of the admin to remove.|


### isAdmin

Checks if an address is an admin of the contract.


```solidity
function isAdmin(address admin) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The address to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is an admin, false otherwise.|


## Events
### Payment

```solidity
event Payment(address from, uint256 amount, bool USDT);
```


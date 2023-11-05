# KronosMultiSig
[Git Source](https://github.com/sammyshakes/kronos-contracts/blob/a868f3b7fb656eca4a74796777cd8445607a8c17/src/KronosMultiSig.sol)

This contract is used to create a multi-sig wallet


## State Variables
### seedSale

```solidity
IKronosSeedSale public seedSale;
```


### requiredConfirmationAddress

```solidity
address public requiredConfirmationAddress;
```


### owners

```solidity
address[] public owners;
```


### isOwner

```solidity
mapping(address => bool) public isOwner;
```


### numConfirmationsRequired

```solidity
uint256 public numConfirmationsRequired;
```


### isConfirmed

```solidity
mapping(uint256 => mapping(address => bool)) public isConfirmed;
```


### transactions

```solidity
Transaction[] public transactions;
```


## Functions
### onlyOwner

Modifier to check if the sender is an owner


```solidity
modifier onlyOwner();
```

### txExists

Modifier to check if a transaction exists


```solidity
modifier txExists(uint256 _txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### notExecuted

Modifier to check if a transaction has not been executed


```solidity
modifier notExecuted(uint256 _txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### notConfirmed

Modifier to check if a transaction has not been confirmed by the sender


```solidity
modifier notConfirmed(uint256 _txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### constructor

Contract constructor


```solidity
constructor(
    address[] memory _owners,
    address _requiredConfirmationAddress,
    uint256 _numConfirmationsRequired
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owners`|`address[]`|The addresses of the owners|
|`_requiredConfirmationAddress`|`address`||
|`_numConfirmationsRequired`|`uint256`|The number of confirmations required for a transaction|


### receive

Fallback function


```solidity
receive() external payable;
```

### setSeedSaleAddress

Set the KRONOS seed sale contract

*This function is called by an owner*


```solidity
function setSeedSaleAddress(address _seedSale) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_seedSale`|`address`|The address of the seed sale contract|


### withdrawTokensFromKronosSeedSale

Withdraw tokens from the KRONOS seed sale contract

*This function is called by an owner*


```solidity
function withdrawTokensFromKronosSeedSale(address token) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to withdraw|


### submitTransaction

Submit a transaction

*This function is called by an owner*


```solidity
function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|The address to send the transaction to|
|`_value`|`uint256`|The amount of ether to send|
|`_data`|`bytes`|The data to send|


### confirmTransaction

Confirm a transaction

*This function is called by an owner*

*This function can only be called if the transaction has not been executed*


```solidity
function confirmTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### executeTransaction

Execute a transaction

*This function is called by an owner*

*This function can only be called if the transaction has enough confirmations*


```solidity
function executeTransaction(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### revokeConfirmation

Revoke a confirmation for a transaction

*This function is called by an owner*


```solidity
function revokeConfirmation(uint256 _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|


### getOwners

Get the owners of the wallet


```solidity
function getOwners() public view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|The owners of the wallet|


### getTransactionCount

Get the transaction count


```solidity
function getTransactionCount() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of transactions|


### getTransaction

Get a transaction


```solidity
function getTransaction(uint256 _txIndex)
    public
    view
    returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_txIndex`|`uint256`|The index of the transaction|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the transaction to|
|`value`|`uint256`|The amount of ether to send|
|`data`|`bytes`|The data to send|
|`executed`|`bool`|Whether or not the transaction has been executed|
|`numConfirmations`|`uint256`|The number of confirmations the transaction has|


## Events
### Deposit

```solidity
event Deposit(address indexed sender, uint256 amount, uint256 balance);
```

### SubmitTransaction

```solidity
event SubmitTransaction(
    address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
);
```

### ConfirmTransaction

```solidity
event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
```

### RevokeConfirmation

```solidity
event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
```

### ExecuteTransaction

```solidity
event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
```

## Structs
### Transaction
Transaction struct


```solidity
struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
    uint256 numConfirmations;
}
```


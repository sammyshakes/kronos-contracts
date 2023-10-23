// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";
//import erc20 mock from openzeppelin
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MultiSigWalletTest is Test {
    ERC20Mock public token;
    MultiSigWallet public wallet;
    address public owner1;
    address public owner2;
    address public owner3;
    address public notAnOwner;

    function setUp() public {
        token = new ERC20Mock();
        owner1 = address(0x1);
        owner2 = address(0x2);
        owner3 = address(0x3);
        notAnOwner = address(0x4);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWallet(owners, 2);

        // deal ether to owners
        vm.deal(owner1, 100 ether);
        vm.deal(owner2, 100 ether);
        vm.deal(owner3, 100 ether);

        //mint tokens to owners
        token.mint(owner1, 1000 ether);
        token.mint(owner2, 1000 ether);
        token.mint(owner3, 1000 ether);

        //mint tokens to wallet
        token.mint(address(wallet), 1000 ether);

        // //approve tokens to wallet
        // vm.prank(owner1);
        // token.approve(address(wallet), 1000 ether);

        //deal ether to this contract
        vm.deal(address(wallet), 100 ether);
    }

    function testERC20Transfer() public {
        uint256 initialBalance = token.balanceOf(owner1);
        uint256 amount = 100 ether;

        // Encoding the function signature and parameters of the ERC20 transferFrom method
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", owner1, amount);

        vm.startPrank(owner1);
        wallet.submitTransaction(address(token), 0, data); // value is 0 for ERC20 transactions
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // we need a second confirmation to execute the transaction
        vm.startPrank(owner2);
        wallet.confirmTransaction(0);
        wallet.executeTransaction(0); // Execute the ERC20 transfer transaction
        vm.stopPrank();

        uint256 finalBalance = token.balanceOf(owner1);
        require(finalBalance - initialBalance == amount, "ERC20 transfer amount mismatch");

        (address to, uint256 value,, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(0);

        assertEq(to, address(token), "Transaction to address should be token address");
        assertEq(value, 0, "Transaction value should be 0");
        assertTrue(executed, "Transaction should be executed");
        assertEq(numConfirmations, 2, "Confirmation count should be 2");

        assertEq(address(wallet).balance, 100 ether, "Contract should have 100 ether");
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(owner1, 100, bytes("test"));
        assertEq(wallet.getTransactionCount(), 1, "Transaction count should be 1");
    }

    function testConfirmTransaction() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(owner1, 100, bytes("test"));

        wallet.confirmTransaction(0);
        vm.stopPrank();

        (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(0);

        assertEq(numConfirmations, 1, "Confirmation count should be 1");
    }

    function testRevokeConfirmation() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(owner1, 100, bytes("test"));

        wallet.confirmTransaction(0);
        wallet.revokeConfirmation(0);
        vm.stopPrank();
        // Destructuring the tuple returned by getTransaction
        (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(0);

        assertEq(numConfirmations, 0, "Confirmation count should be 0");
    }

    function testExecuteTransaction() public {
        //check that contract has 1000 wei
        assertEq(address(wallet).balance, 100 ether, "Contract should have 100 ether");

        // owner1 submits transaction
        vm.startPrank(owner1);
        wallet.submitTransaction(owner2, 100, "");
        // owner1 confirms transaction
        wallet.confirmTransaction(0);
        vm.stopPrank();

        (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) =
            wallet.getTransaction(0);

        console.log("numConfirmations:", numConfirmations);
        console.log("executed:", executed);
        console.log("to:", to);
        console.log("value:", value);

        // owner2 confirms transaction
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        // owner3 executes transaction
        vm.prank(owner3);
        wallet.executeTransaction(0);
        // Destructuring the tuple returned by getTransaction
        (to, value, data, executed, numConfirmations) = wallet.getTransaction(0);

        assertTrue(executed, "Transaction should be executed");
    }

    function testNotOwnerRevert() public {
        vm.expectRevert();
        vm.prank(notAnOwner);
        wallet.submitTransaction(owner1, 100, bytes("test"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/KronosMultiSig.sol";
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MultiSigWalletTest is Test {
    ERC20Mock public token;
    KronosMultiSig public wallet;
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

        wallet = new KronosMultiSig(owners, 2);

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

        (,,,, uint256 numConfirmations) = wallet.getTransaction(0);

        assertEq(numConfirmations, 1, "Confirmation count should be 1");
    }

    function testRevokeConfirmation() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(owner1, 100, bytes("test"));

        wallet.confirmTransaction(0);
        wallet.revokeConfirmation(0);
        vm.stopPrank();
        // Destructuring the tuple returned by getTransaction
        (,,,, uint256 numConfirmations) = wallet.getTransaction(0);

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

    function testMultipleConfirmationsAndExecution() public {
        // Owner1 submits a transaction
        vm.startPrank(owner1);
        wallet.submitTransaction(owner2, 100, "");
        // Owner1 confirms
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner2 confirms
        vm.startPrank(owner2);
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner3 executes
        vm.startPrank(owner3);
        wallet.executeTransaction(0);

        // Check if the transaction was executed successfully
        (,,, bool executed,) = wallet.getTransaction(0);
        assertTrue(executed, "Transaction should be executed");
    }

    function testConfirmationRevocation() public {
        // Owner1 submits a transaction
        vm.startPrank(owner1);
        wallet.submitTransaction(owner2, 100, "");
        // Owner1 confirms
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner1 revokes their confirmation
        vm.startPrank(owner1);
        wallet.revokeConfirmation(0);
        vm.stopPrank();

        // Check if the confirmation was successfully revoked
        (,,,, uint256 numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 0, "Confirmation count should be 0");
    }

    function testInvalidTransaction() public {
        // Submit an invalid transaction (e.g., sending ether to a contract without a receive function)
        vm.startPrank(owner1);
        wallet.submitTransaction(address(this), 100, "");
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner2 confirms the invalid transaction
        vm.startPrank(owner2);
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner3 confirms the invalid transaction
        vm.startPrank(owner3);
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Execute the invalid transaction with three confirmations
        vm.startPrank(owner1);
        vm.expectRevert();
        wallet.executeTransaction(0);
    }

    function testEtherWithdrawal() public {
        uint256 initialBalance = address(wallet).balance;

        // Owner1 withdraws some ether
        vm.startPrank(owner1);
        wallet.submitTransaction(owner1, 50 ether, "");
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner2 confirms the invalid transaction
        vm.startPrank(owner2);
        wallet.confirmTransaction(0);
        vm.stopPrank();

        // Owner3 confirms the invalid transaction
        vm.startPrank(owner3);
        wallet.confirmTransaction(0);
        wallet.executeTransaction(0);
        vm.stopPrank();

        // Check if the balance of the contract decreased
        uint256 finalBalance = address(wallet).balance;
        assertEq(
            finalBalance, initialBalance - 50 ether, "Balance should decrease after withdrawal"
        );
    }

    function testSetSeedSaleAddress() public {
        // Check that the seedSale address is initially set to address(0)
        assertEq(address(wallet.seedSale()), address(0), "Seed sale address should be address(0)");

        // Set the seedSale address
        vm.startPrank(owner1);
        wallet.setSeedSaleAddress(address(this));
        vm.stopPrank();

        // Check that the seedSale address has been updated
        assertEq(address(wallet.seedSale()), address(this), "Seed sale address should be updated");
    }
}

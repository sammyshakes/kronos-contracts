// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import mock erc20 contracts from openzeppelin
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import "forge-std/Test.sol";
import "../src/KronosSeedSale.sol";
import "../src/KronosMultiSig.sol";

contract KronosSeedSaleTest is Test {
    KronosSeedSale public seedSale;
    ERC20Mock public USDT;
    ERC20Mock public USDC;
    address public user1;
    address public user2;
    address public owner;
    address public whitelistedAddress;
    address public withdrawAddress;

    KronosMultiSig public wallet;
    address public owner1;
    address public owner2;
    address public owner3;

    uint256 public minCommitAmount = 250e6;
    uint256 public maxCommitAmount = 5000e6;

    string public baseURI = "http://base-uri.com/";

    address[] admins;

    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        owner = address(0x3);
        whitelistedAddress = address(0x4);

        //setup the multisig wallet
        owner1 = address(0x1);
        owner2 = address(0x2);
        owner3 = address(0x3);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new KronosMultiSig(owners, owner1, 2);

        withdrawAddress = address(wallet);

        USDT = new ERC20Mock();
        USDC = new ERC20Mock();
        seedSale = new KronosSeedSale(address(USDT), address(USDC), withdrawAddress, baseURI);

        //set seed sale address on the multisig wallet
        vm.prank(owner1);
        wallet.setSeedSaleAddress(address(seedSale));

        //set up admin, add admins takes an array of addresses
        admins = new address[](1);
        admins[0] = owner1;
        seedSale.addAdmins(admins);

        //verify isAdmin
        assertEq(seedSale.isAdmin(owner1), true, "Owner1 should be an admin");

        //mint USDT and USDC to user1 and user2
        USDT.mint(whitelistedAddress, minCommitAmount * 100);
        USDC.mint(whitelistedAddress, minCommitAmount * 100);

        // //set baseURI
        // seedSale.setBaseURI("http://base-uri.com/");

        address[] memory wallets = new address[](1);

        wallets[0] = whitelistedAddress;

        // Add an address to the whitelist
        seedSale.addToWhitelist(wallets, 1);

        //verify seed sale is not active
        assertEq(seedSale.seedSaleActive(), false, "Seed sale should not be active");

        //verify minimum commit amount is correct
        assertEq(seedSale.MINIMUM_PAYMENT(), 250e6, "Minimum commit amount should be 250e6");

        //verify maximum total payment is correct
        assertEq(seedSale.MAXIMUM_TOTAL_PAYMENT(), 5000e6, "Maximum total payment should be 5000e6");
    }

    function testAddToWhitelist() public {
        address[] memory wallets = new address[](1);

        wallets[0] = whitelistedAddress;

        // Add an address to the whitelist
        //this one should fail because address is already on the whitelist
        vm.expectRevert();
        seedSale.addToWhitelist(wallets, 2);

        //add a new address to the whitelist
        wallets[0] = user1;
        vm.prank(owner1);
        seedSale.addToWhitelist(wallets, 2);

        // Verify that the address has been added to the whitelist
        bool isWhitelisted = seedSale.isWhitelisted(user1);
        assertEq(isWhitelisted, true, "User1 should be whitelisted");
    }

    function generateAddress(uint256 index) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(index)))));
    }

    function testAddMultipleToWhitelist() public {
        uint256 numAddresses = 50;
        address[] memory wallets = new address[](numAddresses);

        // Generate addresses and NFT IDs to add to the whitelist
        for (uint128 i = 0; i < numAddresses; i++) {
            wallets[i] = generateAddress(i); // Generate a unique address for each
        }

        // Measure gas cost for adding multiple addresses to the whitelist
        uint256 metadataId = 2;
        uint256 gasCost = gasleft();
        vm.prank(owner1);
        seedSale.addToWhitelist(wallets, metadataId);

        // Verify that all addresses have been added to the whitelist correctly
        for (uint256 i = 0; i < numAddresses; i++) {
            assertEq(
                seedSale.metaIDForAddress(wallets[i]),
                metadataId,
                "Address should be on the whitelist with the correct metadata ID"
            );
        }

        gasCost = gasCost - gasleft();

        // // Generate 2nd round
        // for (uint128 i = 0; i < numAddresses; i++) {
        //     wallets[i] = generateAddress(numAddresses + i);
        // }

        // metadataId = 3;
        // seedSale.addToWhitelist(wallets, metadataId);

        // gasCost = gasCost - gasleft();

        // // Verify that all addresses have been added to the whitelist correctly
        // for (uint256 i = 0; i < numAddresses; i++) {
        //     assertEq(
        //         seedSale.metaIDForAddress(wallets[i]),
        //         metadataId,
        //         "Address should be on the whitelist with the correct metadata ID"
        //     );
        // }

        // Print the gas cost
        console.log(
            "Gas cost for adding", numAddresses * 3, "addresses to the whitelist:", gasCost * 3
        );
    }

    // test limits on the amounts that can be committed
    function testCommitLimits() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        vm.stopPrank();

        //get totalcommitted by the whitelisted address
        uint256 committedAmount = seedSale.USDTokenAmountCommitted(whitelistedAddress);
        assertEq(committedAmount, minCommitAmount, "Committed amount should be updated");

        //try to pay more than the max limit of 5000e6
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), 1);
        vm.expectRevert();
        seedSale.payWithUSDT(maxCommitAmount + 1);
        vm.stopPrank();

        //try to pay less than the limit of 250e6
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount - 1);
        vm.expectRevert();
        seedSale.payWithUSDT(minCommitAmount - 1);
        vm.stopPrank();
    }

    // test that more than 250_000e6 cannot be raised
    // we must setup test to raise 250_000e6 first
    // in increments of 5000e6
    function testRaiseLimit() public {
        // create 50 transactions of 5000e6 each
        // with 50 unique addresses, first they must be added to the whitelist
        uint256 numAddresses = 50;
        address[] memory wallets = new address[](numAddresses);

        // Generate addresses to add to the whitelist
        for (uint128 i = 0; i < numAddresses; i++) {
            wallets[i] = generateAddress(i); // Generate a unique address for each
        }

        // set seed sale to active
        seedSale.flipSeedSaleActive();

        // Add addresses to the whitelist
        uint256 metadataId = 2;

        vm.prank(owner1);
        seedSale.addToWhitelist(wallets, metadataId);

        // now these addresses can participate in the seed sale
        // create 50 transactions of 5000e6 each, first we must mint usdt to these addresses
        for (uint128 i = 0; i < numAddresses; i++) {
            USDT.mint(wallets[i], 5000e6);
            vm.startPrank(wallets[i]);
            USDT.approve(address(seedSale), 5000e6);
            seedSale.payWithUSDT(5000e6);
            vm.stopPrank();
        }

        //verify that the total raised amount is 250_000e6
        uint256 raisedAmount = seedSale.totalUSDTokenAmountCommitted();
        assertEq(raisedAmount, 250_000e6, "Raised amount should be 250_000e6");

        //try to raise more than the limit
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), 1);
        vm.expectRevert();
        seedSale.payWithUSDT(1);
        vm.stopPrank();
    }

    function testPayWithUSDC() public {
        seedSale.flipSeedSaleActive();
        uint256 initialContractBalance = USDC.balanceOf(address(seedSale));

        vm.startPrank(whitelistedAddress);
        // Approve USDC transfer
        USDC.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDC(minCommitAmount);
        vm.stopPrank();

        uint256 finalContractBalance = USDC.balanceOf(address(seedSale));
        uint256 committedAmount = seedSale.USDTokenAmountCommitted(whitelistedAddress);

        assertEq(
            finalContractBalance - initialContractBalance,
            minCommitAmount,
            "USDC should be transferred to the contract"
        );
        assertEq(committedAmount, minCommitAmount, "Committed amount should be updated");

        // try to pay more than the max
        vm.startPrank(whitelistedAddress);
        USDC.approve(address(seedSale), minCommitAmount * 100);
        vm.expectRevert();
        seedSale.payWithUSDC(minCommitAmount * 100);
        vm.stopPrank();

        // try to pay less than the min
        vm.startPrank(whitelistedAddress);
        USDC.approve(address(seedSale), minCommitAmount - 1);
        vm.expectRevert();
        seedSale.payWithUSDC(minCommitAmount - 1);
        vm.stopPrank();
    }

    function testPayWithUSDT() public {
        seedSale.flipSeedSaleActive();
        uint256 initialContractBalance = USDT.balanceOf(address(seedSale));

        vm.startPrank(whitelistedAddress);
        // Approve USDT transfer
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        vm.stopPrank();

        uint256 finalContractBalance = USDT.balanceOf(address(seedSale));
        uint256 committedAmount = seedSale.USDTokenAmountCommitted(whitelistedAddress);

        assertEq(
            finalContractBalance - initialContractBalance,
            minCommitAmount,
            "USDT should be transferred to the contract"
        );
        assertEq(committedAmount, minCommitAmount, "Committed amount should be updated");

        // try to pay more than the max
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount * 100);
        vm.expectRevert();
        seedSale.payWithUSDT(minCommitAmount * 100);
        vm.stopPrank();

        // try to pay less than the min
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount - 1);
        vm.expectRevert();
        seedSale.payWithUSDT(minCommitAmount - 1);
        vm.stopPrank();
    }

    // test total committed amount
    function testTotalCommittedAmount() public {
        seedSale.flipSeedSaleActive();
        uint256 initialContractBalance = USDT.balanceOf(address(seedSale));
        uint256 initialTotalCommittedAmount = seedSale.totalUSDTokenAmountCommitted();

        vm.startPrank(whitelistedAddress);
        // Approve USDT transfer
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        vm.stopPrank();

        uint256 finalContractBalance = USDT.balanceOf(address(seedSale));
        uint256 finalTotalCommittedAmount = seedSale.totalUSDTokenAmountCommitted();

        //verify that the total committed amount is updated
        assertEq(
            finalTotalCommittedAmount - initialTotalCommittedAmount,
            minCommitAmount,
            "Total committed amount should be updated"
        );

        assertEq(
            finalContractBalance - initialContractBalance,
            minCommitAmount,
            "USDT should be transferred to the contract"
        );
    }

    function testMint() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        seedSale.mint();
        vm.stopPrank();

        uint256 balance = seedSale.balanceOf(whitelistedAddress);
        assertEq(balance, 1, "NFT should be minted for the whitelisted address");

        //check the owner of the NFT
        owner = seedSale.ownerOf(0);
        assertEq(owner, whitelistedAddress, "Owner of the NFT should be the whitelisted address");

        //verify that the address is no longer on the whitelist
        uint256 metadataId = seedSale.metaIDForAddress(whitelistedAddress);
        assertEq(metadataId, 0, "Address should no longer be on the whitelist");

        //attempt to mint again
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        vm.expectRevert();
        seedSale.mint();
        vm.stopPrank();

        //ensure that the address is stll listed as "whitelisted"
        // Verify that the address is no longer whitelisted after minting
        bool isWhitelistedAfter = seedSale.isWhitelisted(whitelistedAddress);
        assertEq(isWhitelistedAfter, true, "Address should stll be listed as whitelisted");
    }

    function testSetBaseURI() public {
        seedSale.setBaseURI("http://new-base-uri.com/");
        baseURI = seedSale.baseURI();
        assertEq(baseURI, "http://new-base-uri.com/", "Base URI should be updated");
    }

    function testTokenURI() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        seedSale.mint();
        vm.stopPrank();

        string memory tokenURI = seedSale.tokenURI(0);
        console.log("Token URI:", tokenURI);
        assertEq(tokenURI, "http://base-uri.com/1", "Token URI should be constructed correctly");

        //set new baseURI
        seedSale.setBaseURI("http://new-base-uri.com/");
        tokenURI = seedSale.tokenURI(0);
        console.log("Token URI:", tokenURI);
        assertEq(tokenURI, "http://new-base-uri.com/1", "Token URI should be constructed correctly");
    }

    //test withdraw function
    function testWithdraw() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        seedSale.mint();
        vm.stopPrank();

        //get the balance of the withdraw address
        uint256 initialBalance = USDT.balanceOf(withdrawAddress);

        //try to withdraw from non authorized address
        vm.startPrank(user1);
        vm.expectRevert();
        seedSale.withdrawTokens(address(USDT));
        vm.stopPrank();

        //withdraw by calling the withdraw function from the multisig wallet
        vm.prank(owner1);
        wallet.withdrawTokensFromKronosSeedSale(address(USDT));

        //get the balance of the withdraw address
        uint256 finalBalance = USDT.balanceOf(withdrawAddress);

        //verify that the withdraw address received the funds
        assertEq(
            finalBalance - initialBalance,
            minCommitAmount,
            "Withdraw address should receive the funds"
        );
    }

    function testAddAdmin() public {
        // Ensure that the owner can add an admin
        address[] memory adminsToAdd = new address[](1);
        adminsToAdd[0] = owner2;
        seedSale.addAdmins(adminsToAdd);
        assertEq(seedSale.isAdmin(owner2), true, "Owner2 should be an admin");
    }

    function testRemoveAdmin() public {
        seedSale.removeAdmin(owner1);
        assertEq(seedSale.isAdmin(owner1), false, "Owner1 should not be an admin");
    }

    function testIsAdmin() public {
        // Ensure that isAdmin function correctly identifies admins
        assertEq(seedSale.isAdmin(owner1), true, "Owner1 should be an admin");
        assertEq(seedSale.isAdmin(owner2), false, "Owner2 should not be an admin");
    }
}

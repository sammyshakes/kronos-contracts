// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//import mock erc20 contracts from openzeppelin
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import "forge-std/Test.sol";
import "../src/KronosSeedSale.sol";

contract KronosSeedSaleTest is Test {
    KronosSeedSale public seedSale;
    ERC20Mock public USDT;
    ERC20Mock public USDC;
    address public user1;
    address public user2;
    address public owner;
    address public whitelistedAddress;

    uint256 public minCommitAmount = 250e6;

    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        owner = address(0x3);
        whitelistedAddress = address(0x4);

        USDT = new ERC20Mock();
        USDC = new ERC20Mock();
        seedSale = new KronosSeedSale(address(USDT), address(USDC));

        //mint USDT and USDC to user1 and user2
        USDT.mint(whitelistedAddress, minCommitAmount * 100);
        USDC.mint(whitelistedAddress, minCommitAmount * 100);

        //set baseURI
        seedSale.setBaseURI("http://base-uri.com/");

        address[] memory wallets = new address[](1);
        uint128[] memory nftIDs = new uint128[](1);

        wallets[0] = whitelistedAddress;
        nftIDs[0] = 1;

        // Add an address to the whitelist
        seedSale.addToWhitelist(wallets, nftIDs[0]);

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
        seedSale.addToWhitelist(wallets, 2);

        // assertEq(nftId, 2, "Address should be on the whitelist with NFT ID 1");
    }

    function generateAddress(uint256 index) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(index)))));
    }

    function testAddMultipleToWhitelist() public {
        uint256 numAddresses = 150;
        address[] memory wallets = new address[](numAddresses);

        // Generate addresses and NFT IDs to add to the whitelist
        for (uint128 i = 0; i < numAddresses; i++) {
            wallets[i] = generateAddress(i); // Generate a unique address for each
        }

        // Measure gas cost for adding multiple addresses to the whitelist
        uint256 metadataId = 2;
        uint256 gasCost = gasleft();
        seedSale.addToWhitelist(wallets, metadataId);

        // Verify that all addresses have been added to the whitelist correctly
        for (uint256 i = 0; i < numAddresses; i++) {
            assertEq(
                seedSale.metaIDForAddress(wallets[i]),
                metadataId,
                "Address should be on the whitelist with the correct metadata ID"
            );
        }

        // Generate 2nd round
        for (uint128 i = 0; i < numAddresses; i++) {
            wallets[i] = generateAddress(numAddresses + i);
        }

        metadataId = 3;
        seedSale.addToWhitelist(wallets, metadataId);

        gasCost = gasCost - gasleft();

        // Verify that all addresses have been added to the whitelist correctly
        for (uint256 i = 0; i < numAddresses; i++) {
            assertEq(
                seedSale.metaIDForAddress(wallets[i]),
                metadataId,
                "Address should be on the whitelist with the correct metadata ID"
            );
        }

        // Print the gas cost
        console.log("Gas cost for adding", numAddresses * 2, "addresses to the whitelist:", gasCost);
    }

    // test limits on the amounts that can be committed
    function testCommitLimits() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        vm.stopPrank();

        uint256 raisedAmount = seedSale.totalUSDTokenAmountCommitted();
        assertEq(raisedAmount, minCommitAmount, "Raised amount should be 250e6");

        //try to raise more than the limit
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), 1);
        vm.expectRevert();
        seedSale.payWithUSDT(1);
        vm.stopPrank();

        //try to raise less than the limit
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
    }

    function testSetBaseURI() public {
        seedSale.setBaseURI("http://new-base-uri.com/");
        string memory baseURI = seedSale.baseURI();
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
}

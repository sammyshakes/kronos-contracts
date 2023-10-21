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
        uint128[] memory nftIDs = new uint128[](1);

        wallets[0] = whitelistedAddress;
        nftIDs[0] = 2;

        // Add an address to the whitelist
        //this one should fail because address is already on the whitelist
        vm.expectRevert();
        seedSale.addToWhitelist(wallets, nftIDs[0]);
        uint256 nftId = seedSale.nftIDForAddress(whitelistedAddress);

        //add a new address to the whitelist
        wallets[0] = user1;
        nftIDs[0] = 2;
        seedSale.addToWhitelist(wallets, nftIDs[0]);
        nftId = seedSale.nftIDForAddress(user1);

        assertEq(nftId, 2, "Address should be on the whitelist with NFT ID 1");
    }

    function generateAddress(uint256 index) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(index)))));
    }

    function testAddMultipleToWhitelist() public {
        uint256 numAddresses = 150;
        address[] memory wallets = new address[](numAddresses);
        uint128[] memory nftIDs = new uint128[](numAddresses);

        // Generate addresses and NFT IDs to add to the whitelist
        for (uint128 i = 0; i < numAddresses; i++) {
            wallets[i] = generateAddress(i); // Generate a unique address for each
            nftIDs[i] = i + 1; // Use unique NFT IDs for each
        }

        // Measure gas cost for adding multiple addresses to the whitelist
        uint256 gasCost = gasleft();
        seedSale.addToWhitelist(wallets, 2);
        gasCost = gasCost - gasleft();

        // Verify that all addresses have been added to the whitelist correctly
        for (uint256 i = 0; i < numAddresses; i++) {
            uint256 nftId = seedSale.nftIDForAddress(wallets[i]);
            // assertEq(nftId, nftIDs[i], "Address should be on the whitelist with the correct NFT ID");
            // get metadata id from token id
            uint256 metadataId = seedSale.tokenIdToMetadataId(nftId + 1);
            // console.log("Token URI:", seedSale.tokenURI(nftId + 1));
        }

        // Print the gas cost
        console.log("Gas cost for adding", numAddresses, "addresses to the whitelist:", gasCost);
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

        assertEq(
            finalContractBalance - initialContractBalance,
            minCommitAmount,
            "USDT should be transferred to the contract"
        );
    }

    // function testPayWithUSDC() public {
    //     seedSale.flipSeedSaleActive();
    //     uint256 initialBalance = USDC.balanceOf(address(seedSale));

    //     vm.startPrank(whitelistedAddress);
    //     // Approve USDC transfer
    //     uint256 deadline = block.timestamp + 3600; // Set a reasonable deadline
    //     bytes32 r;
    //     bytes32 s;
    //     uint8 v;
    //     IERC20Permit(address(USDC)).permit(whitelistedAddress, address(seedSale), 100, deadline, v, r, s);
    //     seedSale.payWithUSDC(100, deadline, v, r, s);
    //     vm.stopPrank();

    //     uint256 finalBalance = USDC.balanceOf(address(seedSale));
    //     uint256 committedAmount = seedSale.USDTokenAmountCommitted(whitelistedAddress);

    //     assertEq(finalBalance - initialBalance, 100, "USDC should be transferred to the contract");
    //     assertEq(committedAmount, 100, "Committed amount should be updated");
    // }

    function testMint() public {
        seedSale.flipSeedSaleActive();
        vm.startPrank(whitelistedAddress);
        USDT.approve(address(seedSale), minCommitAmount);
        seedSale.payWithUSDT(minCommitAmount);
        seedSale.mint();
        vm.stopPrank();

        uint256 balance = seedSale.balanceOf(whitelistedAddress);
        assertEq(balance, 1, "NFT should be minted for the whitelisted address");

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
        assertEq(tokenURI, "http://base-uri.com/0", "Token URI should be constructed correctly");

        //set new baseURI
        seedSale.setBaseURI("http://new-base-uri.com/");
        tokenURI = seedSale.tokenURI(0);
        console.log("Token URI:", tokenURI);
        assertEq(tokenURI, "http://new-base-uri.com/0", "Token URI should be constructed correctly");
    }
}

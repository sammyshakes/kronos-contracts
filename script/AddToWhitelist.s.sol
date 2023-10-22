// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract AddToWhitelist is Script {
    uint256 deployerPrivateKey = vm.envUint("TESTNET_DEV_DEPLOYER_PRIVATE_KEY");

    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosSeedSale public seedSaleContract;

    uint256 public metaId = 1;

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);
        address[] memory wallets = new address[](3);

        // Populate arrays with random addresses and nft ids
        // These are just for testing purposes
        // In production, you will use the actual addresses and nft ids that you want to whitelist
        wallets[0] = address(0x1);
        wallets[1] = address(0x2);
        wallets[2] = address(0x3);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Add an address to the whitelist
        // seedSaleContract.addToWhitelist(wallets, metaId);

        vm.stopBroadcast();
    }
}

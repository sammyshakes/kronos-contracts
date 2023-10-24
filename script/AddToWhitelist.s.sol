// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract AddToWhitelist is Script {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("TESTNET_DEV_DEPLOYER_PRIVATE_KEY"));

    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosSeedSale public seedSaleContract;

    uint256 public metaId = 1;
    address[] wallets = [address(0x1), address(0x2), address(0x3)];

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Add an address to the whitelist
        seedSaleContract.addToWhitelist(wallets, metaId);

        vm.stopBroadcast();
    }
}

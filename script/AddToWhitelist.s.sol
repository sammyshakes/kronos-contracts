// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract AddToWhitelist is Script {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("TESTNET_DEV_DEPLOYER_PRIVATE_KEY"));

    address public whitlistAddy1 = vm.envAddress("TESTNET_DEV_DEPLOYER_ADDRESS");
    address public whitlistAddy2 = vm.envAddress("SHAKES_DEV_DEPLOYER_ADDRESS");

    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosSeedSale public seedSaleContract;

    uint256 public metaId = 2;
    address[] wallets = [
        whitlistAddy1,
        whitlistAddy2,
        0x396B244C1E40F10E607c4CC7d9dd36992C8Ec681,
        0x858a3D9ceC8502604bA4e90A4e530b097127BC2f,
        0x100444c7D04A842D19bc3eE63cB7b96682FF3f43
    ];
    // address[] wallets = [0x858a3D9ceC8502604bA4e90A4e530b097127BC2f];

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Add an address to the whitelist
        seedSaleContract.addToWhitelist(wallets, metaId);

        vm.stopBroadcast();
    }
}

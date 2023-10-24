// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract AddAdminToSeedSale is Script {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("TESTNET_DEV_DEPLOYER_PRIVATE_KEY"));

    address public whitlistAddy1 = vm.envAddress("TESTNET_DEV_DEPLOYER_ADDRESS");
    address public whitlistAddy2 = vm.envAddress("SHAKES_DEV_DEPLOYER_ADDRESS");

    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosSeedSale public seedSaleContract;

    address[] admins = [
        whitlistAddy2,
        0xe4572D69cDdf8D77a8935B5e1cc5880a750036Fe,
        0xbAf53d5A52bE22497393Fb94Ee8B8fd5576217E4
    ];

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Add an address to the whitelist
        seedSaleContract.addAdmins(admins);

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract DeploySeedSale is Script {
    // Deployments
    KronosSeedSale public seedSaleContract;

    address public usdtAddress = vm.envAddress("USDT_CONTRACT_ADDRESS");
    address public usdcAddress = vm.envAddress("USDC_CONTRACT_ADDRESS");
    address public withdrawAddress = vm.envAddress("WITHDRAW_ADDRESS");
    string public baseURI = vm.envString("KRONOS_BASE_URI");

    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("TESTNET_DEV_DEPLOYER_PRIVATE_KEY"));

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Seed Sale Contract
        seedSaleContract = new KronosSeedSale(usdtAddress, usdcAddress, withdrawAddress, baseURI);

        //switch on the seed sale
        seedSaleContract.flipSeedSaleActive();

        vm.stopBroadcast();
    }
}

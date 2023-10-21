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

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SHAKES_DEV_DEPLOYER_PRIVATE_KEY");

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Seed Sale Contract
        seedSaleContract = new KronosSeedSale(usdtAddress, usdcAddress);

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";

contract FlipSeedSaleActive is Script {
    uint256 deployerPrivateKey = vm.envUint("SHAKES_DEV_DEPLOYER_PRIVATE_KEY");

    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosSeedSale public seedSaleContract;

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        //switch on the seed sale
        seedSaleContract.flipSeedSaleActive();

        vm.stopBroadcast();
    }
}

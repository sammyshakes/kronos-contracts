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
        // whitlistAddy1,
        // whitlistAddy2,
        address(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF),
        address(0xbeEFdeaDBeefDeadBEeFDeAdbEeFDeaDbeefdEad)
    ];

    function run() external {
        seedSaleContract = KronosSeedSale(seedSaleContractAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        // Add an address to the whitelist
        seedSaleContract.addToWhitelist(wallets, metaId);

        vm.stopBroadcast();
    }
}

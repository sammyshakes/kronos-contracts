// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosSeedSale.sol";
import "../src/KronosMultiSig.sol";

contract AddSeedSaleToMultisig is Script {
    uint256 deployerPrivateKey = vm.envUint("TESTNET_DEV_DEPLOYER_PRIVATE_KEY");

    address payable public withdrawAddress = payable(vm.envAddress("KRONOS_MULTISIG_ADDRESS"));
    address public seedSaleContractAddress = vm.envAddress("KRONOS_CONTRACT_ADDRESS");

    KronosMultiSig public wallet;

    function run() external {
        wallet = KronosMultiSig(withdrawAddress);

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        wallet.setSeedSaleAddress(seedSaleContractAddress);

        vm.stopBroadcast();
    }
}

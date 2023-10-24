// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/KronosMultiSig.sol";

contract DeployMultisig is Script {
    // Deployments
    KronosMultiSig public wallet;

    address public owner1 = vm.envAddress("TESTNET_DEV_DEPLOYER_ADDRESS");
    address public owner2 = vm.envAddress("SHAKES_DEV_DEPLOYER_ADDRESS");
    address public owner3;

    address public requiredConfirmationAddress = address(0x1);

    uint256 numComfirmations = 2;

    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("TESTNET_DEV_DEPLOYER_PRIVATE_KEY"));

        owner3 = address(0x3);

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        //Deploy Tronic Master Contracts
        vm.startBroadcast(deployerPrivateKey);

        wallet = new KronosMultiSig(owners, requiredConfirmationAddress, numComfirmations);

        vm.stopBroadcast();
    }
}

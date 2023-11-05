// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../script/DeployMultisig.s.sol";
import "../script/DeploySeedSale.s.sol";
import "../script/AddSeedSaleToMultisig.s.sol";
import "../script/AddAdminToSeedSale.s.sol";
import "../script/AddToWhitelist.s.sol";
import "../script/FlipSeedSaleActive.s.sol";

contract ScriptsTest is Test {
    DeployMultisig public dm;
    DeploySeedSale public ds;
    AddSeedSaleToMultisig public asm;
    AddAdminToSeedSale public aasm;
    AddToWhitelist public atw;
    FlipSeedSaleActive public fsa;

    function setUp() public {
        //Deploy scripts
        dm = new DeployMultisig();
        ds = new DeploySeedSale();
        asm = new AddSeedSaleToMultisig();
        aasm = new AddAdminToSeedSale();
        atw = new AddToWhitelist();
        fsa = new FlipSeedSaleActive();
    }

    function testDeployMultisig() public {
        dm.run();
    }

    function testDeploySeedSale() public {
        ds.run();
    }

    function testAddSeedSaleToMultisig() public {
        asm.run();
    }

    function testAddAdminToSeedSale() public {
        aasm.run();
    }

    function testAddToWhitelist() public {
        atw.run();
    }

    function testFlipSeedSaleActive() public {
        fsa.run();
    }
}

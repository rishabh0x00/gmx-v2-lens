// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import {GMXAggregator} from "src/GMXAggregator.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {console} from "forge-std/console.sol";

contract GMXAggregatorTest is Test {
    address aggregator;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_URL"), 203618435);
        Options memory opts;
        address READER = vm.envAddress("READER_ADDRESS");
        address DATA_STORE = vm.envAddress("DATA_STORE_ADDRESS");
        address ORACLE = vm.envAddress("ORACLE_ADDRESS");
        opts.constructorData = abi.encode(READER, DATA_STORE, ORACLE);
        aggregator = Upgrades.deployUUPSProxy(
            "GMXAggregator.sol",
            abi.encodeCall(GMXAggregator.initialize, ()),
            opts
        );
    }

    function testUpgrade() external {
        Options memory opts;
        address READER = vm.envAddress("READER_ADDRESS");
        address DATA_STORE = vm.envAddress("DATA_STORE_ADDRESS");
        address ORACLE = vm.envAddress("ORACLE_ADDRESS");
        opts.constructorData = abi.encode(READER, DATA_STORE, ORACLE);
        Upgrades.upgradeProxy(aggregator, "GMXAggregator.sol", "", opts);
    }
}

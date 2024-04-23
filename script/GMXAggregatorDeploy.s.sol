// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {GMXAggregator} from "src/GMXAggregator.sol";
import {console} from "forge-std/console.sol";

contract GMXAggregatorScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(uint256(vm.envBytes32("PRIVATE_KEY")));
        Options memory opts;
        address READER = vm.envAddress("READER_ADDRESS");
        address DATA_STORE = vm.envAddress("DATA_STORE_ADDRESS");
        address ORACLE = vm.envAddress("ORACLE_ADDRESS");
        opts.constructorData = abi.encode(READER, DATA_STORE, ORACLE);
        address proxy = Upgrades.deployUUPSProxy(
            "GMXAggregator.sol",
            abi.encodeCall(GMXAggregator.initialize, ()),
            opts
        );
        console.log(proxy);
        vm.stopBroadcast();
    }
}

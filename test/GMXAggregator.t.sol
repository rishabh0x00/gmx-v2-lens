// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import {GMXAggregator} from "src/GMXAggregator.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {console} from "forge-std/console.sol";

contract GMXAggregatorTest is Test {
    GMXAggregator aggregator;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_URL"), 203618435);
        Options memory opts;
        address READER = vm.envAddress("READER_ADDRESS");
        address DATA_STORE = vm.envAddress("DATA_STORE_ADDRESS");
        address ORACLE = vm.envAddress("ORACLE_ADDRESS");
        opts.constructorData = abi.encode(READER, DATA_STORE, ORACLE);
        aggregator = GMXAggregator(
            Upgrades.deployUUPSProxy(
                "GMXAggregator.sol",
                abi.encodeCall(GMXAggregator.initialize, ()),
                opts
            )
        );
    }

    function testGetMarketDataBTC() public view {
        address marketID = address(0x47c031236e19d024b42f8AE6780E44A573170703);
        GMXAggregator.MarketDataState memory marketData = aggregator
            .getMarketData(marketID);
        assertEq(
            marketData.marketToken,
            0x47c031236e19d024b42f8AE6780E44A573170703,
            "Market token address should match dashboard"
        );
        assertEq(
            marketData.indexToken,
            0x47904963fc8b2340414262125aF798B9655E58Cd,
            "Index token address should match dashboard"
        );
        assertEq(
            marketData.longToken,
            0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
            "Long token address should match dashboard"
        );
        assertEq(
            marketData.shortToken,
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            "Short token address should match dashboard"
        );
        assertApproxEqRel(marketData.longTokenAmount, 83769472439, 5e16);
        assertApproxEqRel(marketData.shortTokenAmount, 53253158859101, 5e16);
        assertApproxEqRel(marketData.pnlLong, 309147332897e24, 5e16);
        assertApproxEqRel(marketData.pnlShort, -22294223e29, 5e16);
        assertApproxEqRel(marketData.netPnl, -1.920275e36, 5e16);
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForLongs,
            4432545546888980000000,
            5e16
        );
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForShorts,
            0,
            5e16
        );
        assertEq(marketData.longsPayShorts, true);
        assertApproxEqRel(
            marketData.fundingFactorPerSecond,
            3854474470628320000000,
            5e16
        );
        assertApproxEqRel(marketData.maxOpenInterestUsdLong, 9e37, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdShort, 9e37, 5e16);
    }

    function testGetMarketDataETH() public view {
        address marketID = address(0x70d95587d40A2caf56bd97485aB3Eec10Bee6336);
        GMXAggregator.MarketDataState memory marketData = aggregator
            .getMarketData(marketID);
        assertEq(
            marketData.marketToken,
            0x70d95587d40A2caf56bd97485aB3Eec10Bee6336,
            "Market token address should match dashboard"
        );
        assertEq(
            marketData.indexToken,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            "Index token address should match dashboard"
        );
        assertEq(
            marketData.longToken,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            "Long token address should match dashboard"
        );
        assertEq(
            marketData.shortToken,
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            "Short token address should match dashboard"
        );
        assertApproxEqRel(marketData.longTokenAmount, 15038427974e12, 5e16);
        assertApproxEqRel(marketData.shortTokenAmount, 46277218754061, 5e16);
        assertApproxEqRel(marketData.pnlLong, 1031e33, 5e16);
        assertApproxEqRel(marketData.pnlShort, -1749e33, 5e16);
        assertApproxEqRel(marketData.netPnl, -7175e32, 5e16);
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForLongs,
            5093e18,
            5e16
        );
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForShorts,
            0,
            5e16
        );
        assertEq(marketData.longsPayShorts, true);
        assertApproxEqRel(marketData.fundingFactorPerSecond, 5624e18, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdLong, 8e37, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdShort, 8e37, 5e16);
    }

    function testGetMarketDataDOGE() public view {
        address marketID = address(0x6853EA96FF216fAb11D2d930CE3C508556A4bdc4);
        GMXAggregator.MarketDataState memory marketData = aggregator
            .getMarketData(marketID);
        assertEq(
            marketData.marketToken,
            0x6853EA96FF216fAb11D2d930CE3C508556A4bdc4,
            "Market token address should match dashboard"
        );
        assertEq(
            marketData.indexToken,
            0xC4da4c24fd591125c3F47b340b6f4f76111883d8,
            "Index token address should match dashboard"
        );
        assertEq(
            marketData.longToken,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            "Long token address should match dashboard"
        );
        assertEq(
            marketData.shortToken,
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            "Short token address should match dashboard"
        );
        assertApproxEqRel(marketData.longTokenAmount, 9406e17, 5e16);
        assertApproxEqRel(marketData.shortTokenAmount, 2940917536297, 5e16);
        assertApproxEqRel(marketData.pnlLong, 1708e32, 5e16);
        assertApproxEqRel(marketData.pnlShort, 4814e31, 5e16);
        assertApproxEqRel(marketData.netPnl, 2189e32, 5e16);
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForLongs,
            1031e19,
            5e16
        );
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForShorts,
            0,
            5e16
        );
        assertEq(marketData.longsPayShorts, true);
        assertApproxEqRel(marketData.fundingFactorPerSecond, 3e20, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdLong, 3e36, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdShort, 3e36, 5e16);
    }

    function testGetMarketDataSOL() public view {
        address marketID = address(0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9);
        GMXAggregator.MarketDataState memory marketData = aggregator
            .getMarketData(marketID);
        assertEq(
            marketData.marketToken,
            0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9,
            "Market token address should match dashboard"
        );
        assertEq(
            marketData.indexToken,
            0x2bcC6D6CdBbDC0a4071e48bb3B969b06B3330c07,
            "Index token address should match dashboard"
        );
        assertEq(
            marketData.longToken,
            0x2bcC6D6CdBbDC0a4071e48bb3B969b06B3330c07,
            "Long token address should match dashboard"
        );
        assertEq(
            marketData.shortToken,
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            "Short token address should match dashboard"
        );
        assertApproxEqRel(marketData.longTokenAmount, 65281363298963, 5e16);
        assertApproxEqRel(marketData.shortTokenAmount, 10062954610720, 5e16);
        assertApproxEqRel(marketData.pnlLong, 1059e33, 5e16);
        assertApproxEqRel(marketData.pnlShort, -453735e28, 5e16);
        assertApproxEqRel(marketData.netPnl, 1048e33, 5e16);
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForLongs,
            1331e19,
            5e16
        );
        assertApproxEqRel(
            marketData.borrowingFactorPerSecondForShorts,
            0,
            5e16
        );
        assertEq(marketData.longsPayShorts, true);
        assertApproxEqRel(marketData.fundingFactorPerSecond, 1085e18, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdLong, 175e35, 5e16);
        assertApproxEqRel(marketData.maxOpenInterestUsdShort, 175e35, 5e16);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Market} from "../Market.sol";
import { Price } from '../Price.sol';
import { MarketPoolValueInfo } from '../MarketPoolValueInfo.sol';

interface IReader {
    function getMarket(address dataStore, address key) external view returns (Market.Props memory);

    function getMarketTokenPrice(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, MarketPoolValueInfo.Props memory);

    function getOpenInterestWithPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getNetPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getMarketInfo(
        address dataStore,
        Price.MarketPrices memory prices,
        address marketKey
    ) external view returns (Market.MarketInfo memory);
}
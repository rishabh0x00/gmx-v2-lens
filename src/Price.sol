// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Price {
    // @param marketToken address of the market token for the market
    // @param indexToken address of the index token for the market
    // @param longToken address of the long token for the market
    // @param shortToken address of the short token for the market
    // @param data for any additional data
    struct Props {
        uint256 min;
        uint256 max;
    }

    struct MarketPrices {
        Props indexTokenPrice;
        Props longTokenPrice;
        Props shortTokenPrice;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Market} from "../Market.sol";
import { Price } from '../Price.sol';

interface IPriceFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}
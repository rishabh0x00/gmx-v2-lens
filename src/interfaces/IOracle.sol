// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Price } from '../Price.sol';

interface IOracle {
    function primaryPrices(address token) external view returns (Price.Props memory);
}

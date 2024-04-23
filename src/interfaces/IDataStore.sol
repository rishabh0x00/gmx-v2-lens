// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


interface IDataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function getInt(bytes32 key) external view returns (int256);
    function getAddress(bytes32 key) external view returns (address);
}
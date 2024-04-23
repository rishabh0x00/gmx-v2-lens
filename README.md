# GMX V2 Lens Data Smart Contract

This smart contract is designed to gather identical information from the GMX V2 stats dashboard, providing lens data for market analytics and tracking. It is developed in a foundry-based environment and is UUPS upgradeable.

## Overview

The smart contract includes a `getMarketData` function that returns a `MarketDataState` struct containing various market data metrics. The metrics include information such as market tokens, pool value, token amounts, USD values, open interest, profit and loss (PNL), borrowing factors, funding factors, reserved USD, and maximum open interest USD for both long and short positions.


## Usage

### Build

```shell
$ git submodule init
$ git submodule update
```


```shell
$ forge build
```

### Sample ENV

```
PROXY_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"    // Address of proxy to be updated
ORACLE_ADDRESS = "0xa11B501c2dd83Acd29F6727570f2502FAaa617F2"   // Oracle address
DATA_STORE_ADDRESS = "0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8"   // Data store address
READER_ADDRESS = "0xdA5A70c885187DaA71E7553ca9F728464af8d2ad"   // Reader address
PRIVATE_KEY = <Private Key> // Private key for broadcasting txs
RPC_URL=<RPC>
```

### Test
The fork tests are based on arbitrum off of block number `203618435`, And are expected to match the values specified in `gmx_v2_markets_2024-04-22.csv` procured from GMX dashboard.
```shell
$ forge test
```

### Deploy

```shell
$ forge script script/GMXAggregatorDeploy.s.sol --rpc-url <RPC>
```

### Upgrade

```shell
$ forge script script/GMXAggregatorUpgrade.s.sol --rpc-url <RPC>
```

*Note If you want the txs to be broadcasted too, add --broadcast flag and add --force to recompile
// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    bytes32 public constant OPEN_INTEREST =
        keccak256(abi.encode("OPEN_INTEREST"));
    bytes32 public constant OPEN_INTEREST_IN_TOKENS =
        keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    bytes32 public constant MAX_PNL_FACTOR =
        keccak256(abi.encode("MAX_PNL_FACTOR"));
    bytes32 public constant MAX_OPEN_INTEREST =
        keccak256(abi.encode("MAX_OPEN_INTEREST"));
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    bytes32 public constant FUNDING_EXPONENT_FACTOR =
        keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    bytes32 public constant FUNDING_UPDATED_AT =
        keccak256(abi.encode("FUNDING_UPDATED_AT"));
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    bytes32 public constant PRICE_FEED_MULTIPLIER =
        keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    bytes32 public constant FUNDING_FACTOR =
        keccak256(abi.encode("FUNDING_FACTOR"));

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(OPEN_INTEREST, market, collateralToken, isLong)
            );
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OPEN_INTEREST_IN_TOKENS,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(
        bytes32 pnlFactorType,
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_PNL_FACTOR, pnlFactorType, market, isLong)
            );
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_OPEN_INTEREST, market, isLong));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SAVED_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED, token));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_EXPONENT_FACTOR, market));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_INCREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_STABLE_FUNDING, market));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_DECREASE_FUNDING, market));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_DECREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_UPDATED_AT, market));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED_MULTIPLIER, token));
    }

}

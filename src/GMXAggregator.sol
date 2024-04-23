// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import {IReader} from "./interfaces/IReader.sol";
import {IDataStore} from "./interfaces/IDataStore.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {Market} from "./Market.sol";
import {Keys} from "./Keys.sol";
import {Price} from "./Price.sol";
import {Calc} from "./Calc.sol";
import {Precision} from "./Precision.sol";
import {MarketPoolValueInfo} from "./MarketPoolValueInfo.sol";
import {FundingFactor} from "./FundingFactor.sol";


/// @title GMXAggregator: Aggregator contract for managing market data
/// @custom:oz-upgrades-from GMXAggregator
contract GMXAggregator is UUPSUpgradeable, OwnableUpgradeable {
    using Math for int256;
    using SignedMath for int256;
    using SafeCast for uint256;

    struct MarketDataState {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
        bool longsPayShorts;
        int256 poolValue; // rearranged for storage optimization via variable packing
        uint256 longTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenAmount;
        uint256 shortTokenUsd;
        int256 openInterestLong;
        int256 openInterestShort;
        int256 pnlLong;
        int256 pnlShort;
        int256 netPnl;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        uint256 fundingFactorPerSecond;
        int256 fundingFactorPerSecondLongs;
        int256 fundingFactorPerSecondShorts;
        uint256 reservedUsdLong;
        uint256 reservedUsdShort;
        uint256 maxOpenInterestUsdLong;
        uint256 maxOpenInterestUsdShort;
    }

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IReader private immutable reader;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable dataStore;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable oracle;

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @param reader_ address of reader contract
    /// @param dataStore_ address of dataStore contract
    /// @param oracle_ address of oracle contract
    constructor(IReader reader_, address dataStore_, address oracle_) {
        reader = reader_;
        dataStore = dataStore_;
        oracle = oracle_;
        _disableInitializers();
    }

    /// @dev Initializes the contract
    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    /** @notice Retrieves market data based on the provided market ID
        @param marketID The ID of the market
        @return marketDataState The state of the market data
    */
    function getMarketData(
        address marketID
    ) external view returns (MarketDataState memory marketDataState) {
        Market.Props memory marketProps = reader.getMarket(dataStore, marketID);

        marketDataState.marketToken = marketProps.marketToken;
        marketDataState.indexToken = marketProps.indexToken;
        marketDataState.longToken = marketProps.longToken;
        marketDataState.shortToken = marketProps.shortToken;

        Price.MarketPrices memory marketPrices = Price.MarketPrices(
            getTokenPrice(marketProps.indexToken),
            getTokenPrice(marketProps.longToken),
            getTokenPrice(marketProps.shortToken)
        );
        (, MarketPoolValueInfo.Props memory marketPoolValueInfo) = reader
            .getMarketTokenPrice(
                dataStore,
                marketProps,
                marketPrices.indexTokenPrice,
                marketPrices.longTokenPrice,
                marketPrices.shortTokenPrice,
                Keys.MAX_PNL_FACTOR_FOR_TRADERS,
                true
            );

        marketDataState.poolValue = marketPoolValueInfo.poolValue;
        marketDataState.longTokenAmount = marketPoolValueInfo.longTokenAmount;
        marketDataState.longTokenUsd = marketPoolValueInfo.longTokenUsd;
        marketDataState.shortTokenAmount = marketPoolValueInfo.shortTokenAmount;
        marketDataState.shortTokenUsd = marketPoolValueInfo.shortTokenUsd;

        marketDataState.openInterestLong = getOpenInterest(marketProps, true)
            .toInt256();
        marketDataState.openInterestShort = getOpenInterest(marketProps, false)
            .toInt256();

        marketDataState.pnlLong = reader.getPnl(
            dataStore,
            marketProps,
            marketPrices.indexTokenPrice,
            true,
            false
        );
        marketDataState.pnlShort = reader.getPnl(
            dataStore,
            marketProps,
            marketPrices.indexTokenPrice,
            false,
            false
        );
        marketDataState.netPnl = reader.getNetPnl(
            dataStore,
            marketProps,
            marketPrices.indexTokenPrice,
            false
        );

        Market.MarketInfo memory marketInfo = reader.getMarketInfo(
            dataStore,
            marketPrices,
            marketID
        );

        marketDataState.borrowingFactorPerSecondForLongs = marketInfo
            .borrowingFactorPerSecondForLongs;
        marketDataState.borrowingFactorPerSecondForShorts = marketInfo
            .borrowingFactorPerSecondForShorts;
        marketDataState.longsPayShorts = marketInfo.nextFunding.longsPayShorts;
        marketDataState.fundingFactorPerSecond = marketInfo
            .nextFunding
            .fundingFactorPerSecond;

        uint256 divisor = marketProps.longToken == marketProps.shortToken
            ? 2
            : 1; // calculate divisor firsthand to avoid calulating again

        (
            marketDataState.reservedUsdLong,
            marketDataState.reservedUsdShort
        ) = getReservedUsd(marketProps, marketPrices, divisor);

        marketDataState.maxOpenInterestUsdLong = IDataStore(dataStore).getUint(
            Keys.maxOpenInterestKey(marketID, true)
        );
        marketDataState.maxOpenInterestUsdShort = IDataStore(dataStore).getUint(
            Keys.maxOpenInterestKey(marketID, false)
        );

        marketDataState
            .fundingFactorPerSecondLongs = getNextFundingFactorPerSecond(
            marketProps,
            true,
            divisor
        );
        marketDataState
            .fundingFactorPerSecondShorts = getNextFundingFactorPerSecond(
            marketProps,
            false,
            divisor
        );
    }

    /** @dev get the total reserved USD required for positions
        @param market the market to check
        @param prices the prices of the market tokens
        @param divisor divisor for market
    */
    function getReservedUsd(
        Market.Props memory market,
        Price.MarketPrices memory prices,
        uint256 divisor
    )
        internal
        view
        returns (uint256 reservedUsdLong, uint256 reservedUsdShort)
    {
        uint256 openInterestUsingLongTokenAsCollateralLong = getOpenInterestInTokens(
                market.marketToken,
                market.longToken,
                divisor,
                true
            );
        uint256 openInterestUsingShortTokenAsCollateralLong = getOpenInterestInTokens(
                market.marketToken,
                market.shortToken,
                divisor,
                true
            );
        uint256 openInterestInTokens = openInterestUsingLongTokenAsCollateralLong +
                openInterestUsingShortTokenAsCollateralLong;
        reservedUsdLong = openInterestInTokens * prices.indexTokenPrice.max;
        uint256 openInterestUsingLongTokenAsCollateralShort = getOpenInterest(
            market.marketToken,
            market.longToken,
            false,
            divisor
        );
        uint256 openInterestUsingShortTokenAsCollateralShort = getOpenInterest(
            market.marketToken,
            market.shortToken,
            false,
            divisor
        );

        reservedUsdShort =
            openInterestUsingLongTokenAsCollateralShort +
            openInterestUsingShortTokenAsCollateralShort;
    }

    /** @dev the long and short open interest in tokens for a market based on the collateral token used
        @param market the market to check
        @param collateralToken the collateral token to check
        @param divisor divisor for market
        @param isLong whether to check the long or short side
    */
    function getOpenInterestInTokens(
        address market,
        address collateralToken,
        uint256 divisor,
        bool isLong
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.openInterestInTokensKey(market, collateralToken, isLong)
            ) / divisor;
    }

    /** @dev the long and short open interest for a market based on the collateral token used
        @param market the market to check
        @param collateralToken the collateral token to check
        @param isLong whether to check the long or short side
        @param divisor divisor for market
    */
    function getOpenInterest(
        address market,
        address collateralToken,
        bool isLong,
        uint256 divisor
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.openInterestKey(market, collateralToken, isLong)
            ) / divisor;
    }

    /** @dev get the next funding factor per second
     *  @param market the market to check
     *  @param isLong whether to check the long or short side
     *  @param divisor divisor for market
     */
    function getNextFundingFactorPerSecond(
        Market.Props memory market,
        bool isLong,
        uint256 divisor
    ) internal view returns (int256 nextSavedFundingFactorPerSecond) {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        if (isLong) {
            longOpenInterest = getOpenInterest(
                market.marketToken,
                market.longToken,
                true,
                divisor
            );
            shortOpenInterest = getOpenInterest(
                market.marketToken,
                market.longToken,
                false,
                divisor
            );
        } else {
            longOpenInterest = getOpenInterest(
                market.marketToken,
                market.shortToken,
                true,
                divisor
            );
            shortOpenInterest = getOpenInterest(
                market.marketToken,
                market.shortToken,
                false,
                divisor
            );
        }

        if (longOpenInterest == 0 || shortOpenInterest == 0) {
            return 0;
        }

        (nextSavedFundingFactorPerSecond) = FundingFactor
            .getNextFundingFactorPerSecond(
                dataStore,
                market.marketToken,
                longOpenInterest,
                shortOpenInterest
            );
    }

    /** @dev get either the long or short open interest for a market
     *  @param market the market to check
     *  @param isLong whether to get the long or short open interest
     *  @return the long or short open interest for a market
     */
    function getOpenInterest(
        Market.Props memory market,
        bool isLong
    ) internal view returns (uint256) {
        uint256 divisor = market.longToken == market.shortToken ? 2 : 1;
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterest(
            market.marketToken,
            market.longToken,
            isLong,
            divisor
        );
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterest(
            market.marketToken,
            market.shortToken,
            isLong,
            divisor
        );

        return
            openInterestUsingLongTokenAsCollateral +
            openInterestUsingShortTokenAsCollateral;
    }

    /** @dev get the multiplier value to convert the external price feed price to the price of 1 unit of the token
        represented with 30 decimals
        @param token token to get price feed multiplier for
    */
    function getPriceFeedMultiplier(
        address token
    ) public view returns (uint256) {
        uint256 multiplier = IDataStore(dataStore).getUint(
            Keys.priceFeedMultiplierKey(token)
        );

        return multiplier;
    }

    /** @dev get the token price by fetching token price from token's price feed address in 30 decimals
        @param token token to get price feed multiplier 
    */
    function getTokenPrice(
        address token
    ) internal view returns (Price.Props memory) {
        IPriceFeed priceFeed = IPriceFeed(
            IDataStore(dataStore).getAddress(Keys.priceFeedKey(token))
        );

        if (address(priceFeed) == address(0)) {
            Price.Props memory primaryPrice = IOracle(oracle).primaryPrices(
                token
            );
            require(
                primaryPrice.min != 0 && primaryPrice.max != 0,
                "Not able to fetch latest price"
            );
            return primaryPrice;
        }

        uint256 multiplier = getPriceFeedMultiplier(token);

        (, int256 tokenPrice, , , ) = priceFeed.latestRoundData();

        uint256 price = Precision.mulDiv(
            SafeCast.toUint256(tokenPrice),
            multiplier,
            Precision.FLOAT_PRECISION
        );
        return Price.Props(price, price);
    }

    /**
     * @dev performs required checks required to upgrade contract
     * @param newImplementation address to update implementation logic to
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}

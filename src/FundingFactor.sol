// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Market} from "./Market.sol";
import {Keys} from "./Keys.sol";
import {Price} from "./Price.sol";
import {Calc} from "./Calc.sol";
import {Precision} from "./Precision.sol";
import {IDataStore} from "./interfaces/IDataStore.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";

// Library for calculating funding factor while avoiding Stack too deep error
library FundingFactor {
    using Math for int256;
    using SignedMath for int256;
    using SafeCast for uint256;

    function getNextFundingFactorPerSecond(
        address dataStore,
        address market,
        uint256 longOpenInterest,
        uint256 shortOpenInterest
    ) internal view returns (int256 nextSavedFundingFactorPerSecond) {
        uint256 diffUsd = Calc.diff(longOpenInterest, shortOpenInterest);
        uint256 diffUsdToOpenInterestFactor = calculateDiffUsdToOpenInterestFactor(
                dataStore,
                market,
                diffUsd,
                longOpenInterest,
                shortOpenInterest
            );

        uint256 fundingIncreaseFactorPerSecond = getFundingIncreaseFactorPerSecond(
                dataStore,
                market
            );

        if (fundingIncreaseFactorPerSecond == 0) {
            return 0;
        }

        int256 savedFundingFactorPerSecond = getSavedFundingFactorPerSecond(
            dataStore,
            market
        );
        uint256 thresholdForStableFunding = getThresholdForStableFunding(
            dataStore,
            market
        );
        uint256 thresholdForDecreaseFunding = getThresholdForDecreaseFunding(
            dataStore,
            market
        );

        FundingRateChangeType fundingRateChangeType = determineFundingRateChangeType(
                savedFundingFactorPerSecond,
                longOpenInterest,
                shortOpenInterest,
                diffUsdToOpenInterestFactor,
                thresholdForStableFunding,
                thresholdForDecreaseFunding
            );

        nextSavedFundingFactorPerSecond = calculateNextSavedFundingFactorPerSecond(
            dataStore,
            market,
            savedFundingFactorPerSecond,
            longOpenInterest,
            shortOpenInterest,
            diffUsdToOpenInterestFactor,
            fundingRateChangeType,
            fundingIncreaseFactorPerSecond
        );

        uint256 maxFundingFactorPerSecond = getMaxFundingFactorPerSecond(
            dataStore,
            market
        );
        nextSavedFundingFactorPerSecond = Calc.boundMagnitude(
            nextSavedFundingFactorPerSecond,
            0,
            maxFundingFactorPerSecond
        );
    }

    function calculateDiffUsdToOpenInterestFactor(
        address dataStore,
        address market,
        uint256 diffUsd,
        uint256 longOpenInterest,
        uint256 shortOpenInterest
    ) internal view returns (uint256) {
        uint256 totalOpenInterest = longOpenInterest + shortOpenInterest;
        if (diffUsd == 0) {
            return 0;
        }

        uint256 fundingExponentFactor = IDataStore(dataStore).getUint(
            Keys.fundingExponentFactorKey(market)
        );
        uint256 diffUsdAfterExponent = Precision.applyExponentFactor(
            diffUsd,
            fundingExponentFactor
        );
        return Precision.toFactor(diffUsdAfterExponent, totalOpenInterest);
    }

    function getFundingIncreaseFactorPerSecond(
        address dataStore,
        address market
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.fundingIncreaseFactorPerSecondKey(market)
            );
    }

    function getSavedFundingFactorPerSecond(
        address dataStore,
        address market
    ) internal view returns (int256) {
        return
            IDataStore(dataStore).getInt(
                Keys.savedFundingFactorPerSecondKey(market)
            );
    }

    function getThresholdForStableFunding(
        address dataStore,
        address market
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.thresholdForStableFundingKey(market)
            );
    }

    function getThresholdForDecreaseFunding(
        address dataStore,
        address market
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.thresholdForDecreaseFundingKey(market)
            );
    }

    function determineFundingRateChangeType(
        int256 savedFundingFactorPerSecond,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 diffUsdToOpenInterestFactor,
        uint256 thresholdForStableFunding,
        uint256 thresholdForDecreaseFunding
    ) internal pure returns (FundingRateChangeType) {
        bool isSkewTheSameDirectionAsFunding = (savedFundingFactorPerSecond >
            0 &&
            longOpenInterest > shortOpenInterest) ||
            (savedFundingFactorPerSecond < 0 &&
                shortOpenInterest > longOpenInterest);

        if (isSkewTheSameDirectionAsFunding) {
            if (diffUsdToOpenInterestFactor > thresholdForStableFunding) {
                return FundingRateChangeType.Increase;
            } else if (
                diffUsdToOpenInterestFactor < thresholdForDecreaseFunding
            ) {
                return FundingRateChangeType.Decrease;
            }
        }
        return FundingRateChangeType.Increase;
    }

    function calculateNextSavedFundingFactorPerSecond(
        address dataStore,
        address market,
        int256 savedFundingFactorPerSecond,
        uint256 longOpenInterest,
        uint256 shortOpenInterest,
        uint256 diffUsdToOpenInterestFactor,
        FundingRateChangeType fundingRateChangeType,
        uint256 fundingIncreaseFactorPerSecond
    ) internal view returns (int256) {
        if (fundingRateChangeType == FundingRateChangeType.Increase) {
            int256 increaseValue = Precision
                .applyFactor(
                    diffUsdToOpenInterestFactor,
                    fundingIncreaseFactorPerSecond
                )
                .toInt256() *
                getSecondsSinceFundingUpdated(dataStore, market).toInt256();
            if (longOpenInterest < shortOpenInterest) {
                increaseValue = -increaseValue;
            }
            return savedFundingFactorPerSecond + increaseValue;
        } else if (
            fundingRateChangeType == FundingRateChangeType.Decrease &&
            savedFundingFactorPerSecond.abs() != 0
        ) {
            uint256 fundingDecreaseFactorPerSecond = IDataStore(dataStore)
                .getUint(Keys.fundingDecreaseFactorPerSecondKey(market));
            uint256 decreaseValue = fundingDecreaseFactorPerSecond *
                getSecondsSinceFundingUpdated(dataStore, market);

            if (savedFundingFactorPerSecond.abs() <= decreaseValue) {
                return
                    savedFundingFactorPerSecond /
                    int256(savedFundingFactorPerSecond.abs());
            } else {
                int256 sign = savedFundingFactorPerSecond /
                    int256(savedFundingFactorPerSecond.abs());
                return
                    (savedFundingFactorPerSecond.abs() - decreaseValue)
                        .toInt256() * sign;
            }
        }
        return savedFundingFactorPerSecond;
    }

    function getMaxFundingFactorPerSecond(
        address dataStore,
        address market
    ) internal view returns (uint256) {
        return
            IDataStore(dataStore).getUint(
                Keys.maxFundingFactorPerSecondKey(market)
            );
    }

    // @dev get the number of seconds since funding was updated for a market
    // @param market the market to check
    // @return the number of seconds since funding was updated for a market
    function getSecondsSinceFundingUpdated(
        address dataStore,
        address market
    ) internal view returns (uint256) {
        uint256 updatedAt = IDataStore(dataStore).getUint(
            Keys.fundingUpdatedAtKey(market)
        );
        if (updatedAt == 0) {
            return 0;
        }
        return block.timestamp - updatedAt;
    }

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }
}

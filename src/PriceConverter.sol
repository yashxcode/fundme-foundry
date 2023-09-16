// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Sepolia ETH to USD Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // answer represents Price of ETH in terms of USD; which might be 2000.00000000
        return uint256(answer * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 2000_000000000000000000
        // In solidity, always multiply first and divide later. Ex: 1/2 = 0
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // (2000_000000000000000000 * 1_000000000000000000) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return
            AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
                .version();
    }
}

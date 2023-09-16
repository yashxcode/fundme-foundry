// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256; // all uint256'es now have the access to the functions in PriceConverter library

    uint256 public constant MINIMUM_USD = 5e18;
    // 21,415 gas utilized for viewing MINIMUM_USD - using constant keyword
    // 23,515 gas utilized for viewing MINIMUM_USD - when no using constant

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_owner;

    // 21,508 gas utilized for viewing i_owner - using immutable keyword
    // 23,644 gas utilized for viewing i_owner - when not using immutable

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        // priceFeed object would be taken in when we deploy the contract
        i_owner = msg.sender; // here, since it's a constructor, the sender would be the contract deployer
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // msg.value is the first input parameter being passed to getConversionRate()
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Did not send in enough ETH"
        ); // 1e18 = 1ETH = 10000000000000000000 Wei = 1 * 10 ** 18 Wei
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // resetting the array by creating a new address-type array of the length 0

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // resetting the array by creating a new address-type array of the length 0

        // now, actually withdrawing the funds
        // transfer
        // payable(msg.sender).transfer(address(this).balance); // typecasted msg.sender from an address type to a payable address type
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // this line stores the result of the send operation in the sendSuccess variable
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "The transaction sender isn't the owner of this contract");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // View / Pure functions (Getters)
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

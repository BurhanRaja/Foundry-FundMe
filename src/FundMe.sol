// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

/// @title A Smart Contract for Crowd Funding
/// @author Burhan Raja
/// @notice
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 4e18;
    AggregatorV3Interface private s_priceFeed; // s_priceFeed Aggregator
    address public immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Get Price feed address
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    // What if someone send money to us without initiating fund function

    // recieve()
    // fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH."
        );

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        // resetting the array
        s_funders = new address[](0);
        // Withdraw all the ETH balance

        // ? transfer - limited Gas and throws Error
        // payable(msg.sender).transfer(address(this).balance);

        // ? send - limited Gas and returns bool
        // ? bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // ? require(sendSuccess, "Send Failed");

        // call - All Gas and returns bool
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (uint i = 0; i < funders.length; i++) {
            s_addressToAmountFunded[funders[i]] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmount(address add) public view returns (uint256) {
        return s_addressToAmountFunded[add];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}

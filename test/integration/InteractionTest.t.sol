// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interaction.s.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";

contract InteractionTest is Test {
    FundMe fundMe;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_VALUE = 10 ether;
    // uint256 public constant GAS_PRICE = 1;

    address USER = makeAddr("burhan");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    function testUserCanFundInteraction() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assertEq(address(fundMe).balance, 0);
    }
}

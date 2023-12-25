// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";

// forge test -vv (console's the two console log)
// forge script script/... --fork-url SEPOLIA_RPC_URL (It will create an evironment like sepolia but not on actual testnet)
// forge coverage --fork-url SEPOLIA_RPC_URL

contract FundMeTest is Test {
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

    function testMinimumDollarIsFour() public {
        console.log(fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 4e18);
    }

    function testContractOwner() public {
        console.log(fundMe.getOwner());
        assertEq(fundMe.getOwner(), msg.sender);
        // msg.sender becoz, now the contract is running on the local chain and returning from the Deployed Script
        // address(this) becoz, us (calling)-> FundMeTest (calling)-> FundMe
    }

    modifier funded() {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();
        _;
    }

    function testFundingByUser() public funded {
        uint256 amountFunded = fundMe.getAddressToAmount(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testUserAddedToFundersArray() public funded {
        address funderAddress = fundMe.getFunders(0);
        assertEq(funderAddress, USER);
    }

    function testWithdrawFundRevert() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleUserFund() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleUserFund() public funded {
        uint160 totalUsers = 10;
        uint160 startingindex = 1;

        for (uint160 i = startingindex; i < totalUsers; i++) {
            hoax(address(i), STARTING_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); // 487600 to 486644
        vm.stopPrank();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assert(endingContractBalance == 0);
        assert(
            startingOwnerBalance + startingContractBalance == endingOwnerBalance
        );
    }

    function testCheaperWithdrawWithMultipleUserFund() public funded {
        uint160 totalUsers = 10;
        uint160 startingindex = 1;

        for (uint160 i = startingindex; i < totalUsers; i++) {
            hoax(address(i), STARTING_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); // 487600 to 486644
        vm.stopPrank();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assert(endingContractBalance == 0);
        assert(
            startingOwnerBalance + startingContractBalance == endingOwnerBalance
        );
    }
}

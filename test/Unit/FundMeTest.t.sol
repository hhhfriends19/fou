//SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        // us -> FundMeTest -> FundMe
        // msg.sender 是发布 FundMeTest 的地址，而 FundMeTest 才是发布 FundMe 的地址
        // 所以 i_owner 不等于 msg.sender，因为 i_owner = FundMeTest 的地址
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIOwnerIsMsgSender() public {
        // address(this) 指的是 FundMe 的人，即是 FundMeTest 的地址
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(uint256(fundMe.getVersion()), 4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line, should revert!
        // assert(This tx fails/reverts)
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER); // THE next tx will be sent by USER
        // fundMe.fund{value: SEND_VALUE}(); // 10e18 就是 10 eth
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        // startingFunderIndex 不从0开始，是因为有时候 index0 会被 revert，为了确保万无一失，还是从 index1开始
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // fund the fundMe
            // 也可以使用 forge standard library 的 hoax，hoax 相当于 prank 和 deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); // should have spant gas?
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithDrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        // startingFunderIndex 不从0开始，是因为有时候 index0 会被 revert，为了确保万无一失，还是从 index1开始
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // fund the fundMe
            // 也可以使用 forge standard library 的 hoax，hoax 相当于 prank 和 deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); // should have spant gas?
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    // 1.uint
    //     - Testing a specific part of our code
    // 2.Integration
    //     - Testing how our code works with other parts of our code
    // 3.Forked
    //     - Testing our code on a simulated real environment
    // 4.Staging
    //     - Testing our code in a real environment that is not prod
}

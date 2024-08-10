// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";

contract StakingTest is Test {
    Staking staking;
    address user1;
    address user2;
    uint256 constant DAY = 1 days;

    function setUp() public {
        staking = new Staking();
        user1 = address(0x123);
        user2 = address(0x456);
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
    }

    function testStakeEther() public {
        vm.startPrank(user1);
        uint256 numDays = 30;
        uint256 stakeAmount = 0.1 ether;

        uint256 initialBalance = user1.balance;
        staking.stakeEther{value: stakeAmount}(numDays);

        Staking.Position memory position = staking.getPositionById(0);
        assertEq(position.walletAddress, user1);
        assertEq(position.weiStaked, stakeAmount);
        assertEq(position.unlockDate, block.timestamp + (numDays * DAY));
        assertTrue(position.open);
        assertEq(user1.balance, initialBalance - stakeAmount);
    }

    function testCalculateInterest() public view {
        uint256 basePoints = 800; 
        uint256 weiAmount = 1 ether;
        
        uint256 interest = staking.calculateInterest(basePoints, weiAmount);
        assertEq(interest, 0.08 ether);
    }

    function testGetLockPeriods() public view {
        uint256[] memory lockPeriods = staking.getLockPeriods();
        assertEq(lockPeriods.length, 4);
        assertEq(lockPeriods[0], 0);
        assertEq(lockPeriods[1], 30);
        assertEq(lockPeriods[2], 60);
        assertEq(lockPeriods[3], 90);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract TestCheatCode is Test {

    function setUp() public {
        
    } 

    //改变区块号
    function test_Roll() public{
        console.log("current blockNumber :", block.number);

        uint256 newBlockNumber = 269;
        vm.roll(newBlockNumber);
        console.log("after vm.roll, blockNumber :", block.number);
        assertEq(block.number, newBlockNumber);
    }

    //改变区块时间戳
    function test_WarpAndSkip() public{
        console.log("current timestamp :", block.timestamp);

        uint256 newTimestamp = 1764336476;
        vm.warp(newTimestamp);
        console.log("after vm.warp, timestamp :", block.timestamp);
        assertTrue(block.timestamp == newTimestamp, "vm.warp is not as expected!");

        //前进1小时
        skip(3600);
        console.log("after skip, timestamp :", block.timestamp);
        assertEq(block.timestamp, newTimestamp + 3600);

    }

}    
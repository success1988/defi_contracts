// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SuccessTokenWithCallback.sol";

contract TestCheatCode is Test {

    uint256 public sepoliaForkId;
    SuccessTokenWithCallback public testSstToken;

    function setUp() public {
        uint forkBlock = 9666004;
        sepoliaForkId = vm.createFork(vm.rpcUrl("sepolia"), forkBlock);   

        testSstToken = new  SuccessTokenWithCallback(1000000);    
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


    //分叉测试
    function test_Fork() public{
        vm.selectFork(sepoliaForkId);
        assertEq(vm.activeFork(), sepoliaForkId);

        SuccessTokenWithCallback sstToken = SuccessTokenWithCallback(0x80317e662c0799B5f5656F5207F883fB1d75Ccc9);
        uint amount = sstToken.balanceOf(0x2D6cD17981dB1eFB171d6cEB997844798C68b9CF);
        uint total = sstToken.totalSupply();
        console.log("current token amount:", amount);
        console.log("sst token totalSupply:", total);
        assertLe(amount, total, "amount should be less or equal totalSupply");
    }
    

    //模糊测试
    function testFuzz_TransferERC20(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != address(this));

        amount = bound(amount, 0, 1000e18);
        testSstToken.transfer(to, amount);
        assertEq(amount, testSstToken.balanceOf(to));
    }

}    
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract TestAssert is Test {
    Bank public bank;

    function setUp() public {
        bank = new Bank();
    }

    function testBasicAssertions() public pure{
        uint256 a = 100;
        uint256 b = 200;
        
        // 相等断言
        assertEq(a, 100, "a should be 100");
        assertEq(bytes("hello"), bytes("hello"), "strings should match");
        
        // 不等断言
        assertNotEq(a, b, "a should not equal b");
    }

    function testBooleanAssertions() public pure{
        bool success = true;
        bool failure = false;
        
        assertTrue(success, "Should be true");
        assertFalse(failure, "Should be false");
    }
  
    function testComparisonAssertions() public pure{
        uint256 small = 10;
        uint256 large = 20;
        
        assertGt(large, small, "large should be greater than small");
        assertGe(large, small, "large should be greater or equal");
        assertLt(small, large, "small should be less than large");
        assertLe(small, large, "small should be less or equal");
    }

    function testAddressAssertions() public{
        address alice = makeAddr("alice");
        
        // 地址相等
        assertEq(alice, alice, "addresses should match");
        
        // 检查EOA代码大小为0
        //默认情况下，makeAddr 返回的地址是 EOA（因为还没有代码），但你可以通过其他操作使其变成合约地址
        address eoa = makeAddr("eoa");
        assertEq(eoa.code.length, 0, "EOA should have no code");
    }

    function testApproximateAssertions() public pure{
        uint256 exact = 1000;
        uint256 approximate = 1005;
        
        // 绝对误差
        assertApproxEqAbs(approximate, exact, 10, "within 10 absolute difference");
        
        // 相对误差
        //0.01e18 表示最大相对误差为1%（因为0.01e18 = 0.01 * 10^18 = 1e16，但是注意，这里的1%是用1e16表示的，因为1e18对应100%）
        assertApproxEqRel(approximate, exact, 0.01e18, "within 1% relative difference");
    }

    function testArrayAssertions() public pure{
        uint256[] memory arr1 = new uint256[](3);
        arr1[0] = 1;
        arr1[1] = 2;
        arr1[2] = 3;
        
        uint256[] memory arr2 = new uint256[](3);
        arr2[0] = 1;
        arr2[1] = 2;
        arr2[2] = 3;
        
        // 数组相等
        assertEq(arr1, arr2, "arrays should be equal");
        
        // 检查数组是否包含元素 2
        bool found = false;
        for (uint256 i = 0; i < arr2.length; i++) {
            if (arr2[i] == 2) {
                found = true;
                break;
            }
        }
        assertTrue(found, "array should contain 2");
    }

    function testBytesAssertions() public pure{
        bytes memory data1 = hex"123456";
        bytes memory data2 = hex"123456";
        
        assertEq(data1, data2, "bytes should be equal");
        
        bytes32 hash1 = keccak256(abi.encodePacked("test"));
        bytes32 hash2 = keccak256(abi.encodePacked("test"));
        
        assertEq(hash1, hash2, "hashes should match");
    }



    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    
    //测试合约执⾏是否有出现符合预期的合约Event记录
    function testEventAssertions() public {
        address user1 = makeAddr("bob");
        vm.deal(user1, 2 ether);
        uint256 initialUserBalance = user1.balance;
        console.log("user1", user1, "initialUserBalance", initialUserBalance);
        
        vm.prank(user1);
        //四个布尔参数，分别对应事件中的三个索引参数（topics）和一个数据（data）部分
        vm.expectEmit(true, true, true, true); 
        emit Deposit(address(user1), 1e18);
        bank.deposit{value: 1 ether}();
    }


    //断⾔合约执⾏错误
    //vm.expectRever t() / expectRever t(bytes4 rever tData) / expectRever t(bytes calldata rever tData)
    function testRevertAssertions() public {
        address user2 = makeAddr("Alice");

        vm.prank(user2);
        // 期望调用会回滚
        vm.expectRevert("Insufficient balance");
        bank.withdraw(200);
        
        vm.prank(user2);
        // 或者检查特定错误
        bytes memory data = abi.encodeWithSignature("NotOwner(address)", user2);
        vm.expectRevert(data);
        bank.emergencyWithdraw();
    }

}
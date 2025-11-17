// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SuccessTokenWithCallback.sol";

contract SuccessTokenWithCallbackTest is Test {
    SuccessTokenWithCallback public token;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    
    function setUp() public {
        vm.prank(owner);
        token = new SuccessTokenWithCallback(1000000); // 100万代币
    }
    
    function test_InitialSupply() public {
        assertEq(token.totalSupply(), 1000000 * 10 ** token.decimals());
        assertEq(token.balanceOf(owner), 1000000 * 10 ** token.decimals());
    }
    
    function test_TransferAndCall() public {
        vm.prank(owner);
        token.transfer(user1, 1000);
        
        // 创建一个测试合约来接收回调
        TestCallbackReceiver receiver = new TestCallbackReceiver();
        
        vm.prank(user1);
        bytes memory testData = abi.encode("test data");
        bool success = token.transferAndCall(address(receiver), 500, testData);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), 500);
        assertEq(token.balanceOf(address(receiver)), 500);
        
        // 验证回调被触发
        assertTrue(receiver.callbackReceived());
        assertEq(receiver.lastOperator(), user1);
        assertEq(receiver.lastFrom(), user1);
        assertEq(receiver.lastAmount(), 500);
        assertEq(receiver.lastData(), testData);
    }
    
    function test_TransferAndCallToEOA() public {
        vm.prank(owner);
        token.transfer(user1, 1000);
        
        bytes memory testData = abi.encode("test data");
        
        vm.prank(user1);
        bool success = token.transferAndCall(user2, 500, testData);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), 500);
        assertEq(token.balanceOf(user2), 500);
    }
    
    function test_TransferFromAndCall() public {
        vm.prank(owner);
        token.transfer(user1, 1000);
        
        // 授权给user2
        vm.prank(user1);
        token.approve(user2, 500);
        
        TestCallbackReceiver receiver = new TestCallbackReceiver();
        bytes memory testData = abi.encode("approval data");
        
        vm.prank(user2);
        bool success = token.transferFromAndCall(user1, address(receiver), 300, testData);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), 700);
        assertEq(token.balanceOf(address(receiver)), 300);
        assertEq(token.allowance(user1, user2), 200);
        
        assertTrue(receiver.callbackReceived());
        assertEq(receiver.lastOperator(), user2);
        assertEq(receiver.lastFrom(), user1);
    }
    
    function test_MintAndBurn() public {
        uint256 initialBalance = token.balanceOf(owner);
        
        vm.prank(owner);
        token.mint(user1, 1000);
        assertEq(token.balanceOf(user1), 1000);
        
        vm.prank(user1);
        token.burn(500);
        assertEq(token.balanceOf(user1), 500);
    }
    
    function test_OnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, 1000);
    }
}

// 测试回调接收合约
contract TestCallbackReceiver {
    address public lastOperator;
    address public lastFrom;
    uint256 public lastAmount;
    bytes public lastData;
    bool public callbackReceived;
    
    function onTransferReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        lastOperator = operator;
        lastFrom = from;
        lastAmount = amount;
        lastData = data;
        callbackReceived = true;
        
        return bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
    }
}
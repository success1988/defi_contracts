// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    
    // 使用非预编译合约地址
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    
    // 定义事件签名以用于测试
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    function setUp() public {
        vm.startPrank(owner);
        bank = new Bank();
        vm.stopPrank();
    }
    
    function testDeposit() public {
        vm.deal(user1, 1 ether);
        uint256 initialBalance = user1.balance;
        
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        assertEq(bank.getContractBalance(), 1 ether);
        assertEq(bank.balances(user1), 1 ether);
        assertEq(user1.balance, initialBalance - 1 ether);
    }
    
    function testWithdraw() public {
        // 先存款
        vm.deal(user1, 2 ether);
        uint256 initialUserBalance = user1.balance;
        
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        // 再取款
        uint256 balanceBeforeWithdraw = user1.balance;
        vm.prank(user1);
        bank.withdraw(0.5 ether);
        
        assertEq(bank.balances(user1), 0.5 ether); // 剩余余额
        assertEq(user1.balance, balanceBeforeWithdraw + 0.5 ether); // 取回0.5 ETH
        assertEq(bank.getContractBalance(), 0.5 ether); // 合约剩余余额
    }
    
    function test_RevertWhen_WithdrawInsufficientBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(1 ether);
    }
    
    function test_RevertWhen_EmergencyWithdrawNotOwner() public {
        vm.prank(user1);
        bytes memory data = abi.encodeWithSignature("NotOwner(address)", user1);
        vm.expectRevert(data);
        bank.emergencyWithdraw();
    }
    
    function testEmergencyWithdraw() public {
        // 用户存款
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        // 记录所有者初始余额
        uint256 ownerInitialBalance = owner.balance;
        uint256 contractBalanceBefore = bank.getContractBalance();
        
        // 所有者紧急提取
        vm.prank(owner);
        bank.emergencyWithdraw();
        
        assertEq(bank.getContractBalance(), 0);
        assertEq(owner.balance, ownerInitialBalance + contractBalanceBefore);
    }
    
    function test_RevertWhen_DepositZero() public {
        vm.prank(user1);
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.deposit{value: 0}();
    }
    
    function test_RevertWhen_WithdrawMoreThanContractBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 0.1 ether}();
        
        // 其他用户存款
        vm.deal(user2, 0.1 ether);
        vm.prank(user2);
        bank.deposit{value: 0.1 ether}();
        
        // 现在合约有0.2 ETH，用户1尝试提取超过自己余额但不超过合约余额
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(0.2 ether);
    }
    
    // 新增测试：合约资金不足的情况
    function test_RevertWhen_ContractInsufficientFunds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        // 所有者提取所有资金
        vm.prank(owner);
        bank.emergencyWithdraw();
        
        // 用户尝试提取（合约没有资金了）
        vm.prank(user1);
        vm.expectRevert("Contract has insufficient funds");
        bank.withdraw(0.1 ether);
    }
    
    function testGetBalance() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        bank.deposit{value: 1.5 ether}();
        
        // 使用 bank.getBalance() 需要指定调用者
        vm.prank(user1);
        uint256 userBalance = bank.getBalance();
        
        assertEq(userBalance, 1.5 ether);
        assertEq(bank.balances(user1), 1.5 ether);
    }
    
    function testGetContractBalance() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        vm.prank(user2);
        bank.deposit{value: 0.3 ether}();
        
        assertEq(bank.getContractBalance(), 0.8 ether);
    }
    
    function testEvents() public {
        vm.deal(user1, 1 ether);
        
        // 测试 Deposit 事件
        vm.expectEmit(true, true, false, true);
        emit Deposit(user1, 1 ether);
        
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        // 测试 Withdraw 事件
        vm.expectEmit(true, true, false, true);
        emit Withdraw(user1, 0.5 ether);
        
        vm.prank(user1);
        bank.withdraw(0.5 ether);
    }

    function testMultipleUsers() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        // 用户1存款
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        // 用户2存款
        vm.prank(user2);
        bank.deposit{value: 0.3 ether}();
        
        assertEq(bank.balances(user1), 0.5 ether);
        assertEq(bank.balances(user2), 0.3 ether);
        assertEq(bank.getContractBalance(), 0.8 ether);
    }
    
    function testOwner() public {
        assertEq(bank.owner(), owner);
    }
    
    // 测试只能提取自己的余额
    function testCannotWithdrawOthersBalance() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        // 用户1存款
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        // 用户2尝试提取用户1的余额
        vm.prank(user2);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(0.1 ether);
    }
}
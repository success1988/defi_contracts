// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SuccessTokenWithCallback.sol";
import "../src/SuccessTokenBankWithCallback.sol";

contract SuccessTokenBankWithCallbackTest is Test {
    SuccessTokenWithCallback public token;
    SuccessTokenBankWithCallback public bank;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    // 事件
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event AutoDeposited(address indexed from, uint256 amount, bytes data);
    
    function setUp() public {
         // 首先检查初始状态
        console.log("=== Starting Setup ===");
        
        vm.prank(owner);
        // 初始供应量：20000 个代币
        token = new SuccessTokenWithCallback(20000);
        
        console.log("Token deployed, total supply:", token.totalSupply());
        console.log("Owner initial balance:", token.balanceOf(owner));
        
        vm.prank(owner);
        bank = new SuccessTokenBankWithCallback(address(token));
        
        // 给用户分配代币前再次检查余额
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        console.log("Owner balance before transfers:", ownerBalanceBefore);
        
        // 给用户分配代币 - 各5000个代币
        uint256 userAllocation = 5000 * 10 ** token.decimals();
        console.log("Each user allocation:", userAllocation);
        console.log("Total allocation needed:", userAllocation * 2);
        
        // 检查是否有足够余额
        require(ownerBalanceBefore >= userAllocation * 2, "Owner has insufficient balance for allocation");
        
        vm.prank(owner);
        token.transfer(user1, userAllocation);
        
        vm.prank(owner);
        token.transfer(user2, userAllocation);
        
        // 验证分配后的余额
        console.log("=== After Distribution ===");
        console.log("Owner balance:", token.balanceOf(owner));
        console.log("User1 balance:", token.balanceOf(user1));
        console.log("User2 balance:", token.balanceOf(user2));
        console.log("Bank balance:", token.balanceOf(address(bank)));
        console.log("Total supply:", token.totalSupply());
        
        // 验证总和是否正确
        uint256 totalAfter = token.balanceOf(owner) + token.balanceOf(user1) + token.balanceOf(user2) + token.balanceOf(address(bank));
        console.log("Sum of all balances:", totalAfter);
        assertEq(totalAfter, token.totalSupply(), "Total balances should equal total supply");
    }
    
    function test_Deposit() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        
        vm.prank(user1);
        bank.deposit(depositAmount);
        
        assertEq(bank.getDepositBalance(user1), depositAmount);
        assertEq(token.balanceOf(user1), 4000 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(bank)), depositAmount);
    }
    
    function test_Withdraw() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        uint256 withdrawAmount = 500 * 10 ** token.decimals();
        
        // 先存款
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        vm.prank(user1);
        bank.deposit(depositAmount);
        
        // 再取款
        vm.prank(user1);
        bank.withdraw(withdrawAmount);
        
        assertEq(bank.getDepositBalance(user1), withdrawAmount);
        assertEq(token.balanceOf(user1), 4500 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(bank)), withdrawAmount);
    }
    
    function test_AutoDepositViaTransferAndCall() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        bytes memory depositData = abi.encode("auto deposit");
        
        vm.prank(user1);
        bool success = token.transferAndCall(address(bank), depositAmount, depositData);
        
        assertTrue(success);
        assertEq(bank.getDepositBalance(user1), depositAmount);
        assertEq(token.balanceOf(user1), 4000 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(bank)), depositAmount);
    }
    
    function test_DepositWithData() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        bytes memory customData = abi.encode("custom deposit data");
        
        // 需要先授权给银行合约
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        
        vm.prank(user1);
        bank.depositWithData(depositAmount, customData);
        
        assertEq(bank.getDepositBalance(user1), depositAmount);
        assertEq(token.balanceOf(user1), 4000 * 10 ** token.decimals());


        uint256 depositAmount = 1000 * 10 ** token.decimals();
        
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        
        vm.prank(user1);
        bank.deposit(depositAmount);
        
        assertEq(bank.getDepositBalance(user1), depositAmount);
        assertEq(token.balanceOf(user1), 4000 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(bank)), depositAmount);
    }
    
    function test_ReentrancyProtection() public {
        // 创建一个恶意合约尝试重入攻击
        MaliciousBank attacker = new MaliciousBank(address(token), address(bank));
        
        // 给恶意合约转账一些代币
        vm.prank(owner);
        token.transfer(address(attacker), 1000 * 10 ** token.decimals());
        
        // 应该被重入保护阻止
        vm.expectRevert("ReentrancyGuard: reentrant call");
        attacker.attack();
    }
    
    function test_OnlyTokenCanCallCallback() public {
        // 尝试直接调用回调函数（非token合约调用）
        vm.expectRevert("Only token can call");
        bank.onTransferReceived(user1, user1, 1000, "");
    }
    
    function test_GetTotalDeposits() public {
        uint256 depositAmount1 = 1000 * 10 ** token.decimals();
        uint256 depositAmount2 = 500 * 10 ** token.decimals();
        
        vm.prank(user1);
        token.approve(address(bank), depositAmount1);
        vm.prank(user1);
        bank.deposit(depositAmount1);
        
        vm.prank(user2);
        token.approve(address(bank), depositAmount2);
        vm.prank(user2);
        bank.deposit(depositAmount2);
        
        assertEq(bank.getTotalDeposits(), depositAmount1 + depositAmount2);
    }
    
    function test_FuzzDepositWithdraw(uint256 rawDepositAmount, uint256 rawWithdrawAmount) public {
        // 限制金额范围以避免溢出
        uint256 depositAmount = bound(rawDepositAmount, 1, 5000);
        uint256 withdrawAmount = bound(rawWithdrawAmount, 1, depositAmount);
        
        depositAmount = depositAmount * 10 ** token.decimals();
        withdrawAmount = withdrawAmount * 10 ** token.decimals();
        
        // 存款
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        vm.prank(user1);
        bank.deposit(depositAmount);
        
        uint256 initialUserBalance = token.balanceOf(user1);
        uint256 initialDepositBalance = bank.getDepositBalance(user1);
        
        // 取款
        vm.prank(user1);
        bank.withdraw(withdrawAmount);
        
        assertEq(bank.getDepositBalance(user1), initialDepositBalance - withdrawAmount);
        assertEq(token.balanceOf(user1), initialUserBalance + withdrawAmount);
    }
    
    function test_CallbackReturnValue() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        bytes memory depositData = abi.encode("test data");
        
        vm.prank(user1);
        bool success = token.transferAndCall(address(bank), depositAmount, depositData);
        
        assertTrue(success);
    }
    
    function test_EventEmission() public {
        uint256 depositAmount = 1000 * 10 ** token.decimals();
        bytes memory depositData = abi.encode("event test");
        
        vm.prank(user1);
        token.approve(address(bank), depositAmount);
        
        // 测试传统存款事件
        vm.expectEmit(true, true, true, true);
        emit Deposited(user1, depositAmount);
        
        vm.prank(user1);
        bank.deposit(depositAmount);
        
        // 测试自动存款事件
        vm.expectEmit(true, true, true, true);
        emit AutoDeposited(user1, depositAmount, depositData);
        
        vm.prank(user1);
        token.transferAndCall(address(bank), depositAmount, depositData);
    }
}

// 修复后的恶意合约用于测试重入保护
contract MaliciousBank {
    SuccessTokenWithCallback public token;
    SuccessTokenBankWithCallback public bank;
    bool private attacking;
    
    constructor(address _token, address _bank) {
        token = SuccessTokenWithCallback(_token);
        bank = SuccessTokenBankWithCallback(_bank);
    }
    
    function attack() external {
        // 先通过transferAndCall存款
        bytes memory data = abi.encode("attack");
        token.transferAndCall(address(bank), 100 * 10 ** token.decimals(), data);
    }
    
    function onTransferReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        // 在回调函数中尝试重入攻击
        if (msg.sender == address(token) && !attacking) {
            attacking = true;
            // 尝试在回调中再次调用银行合约 - 这应该被重入保护阻止
            bank.withdraw(amount);
        }
        
        return bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
    }
    
    // 添加fallback函数以防万一
    fallback() external payable {}
    receive() external payable {}
}

// 另一个重入攻击测试合约 - 测试存款时的重入
contract MaliciousBankDeposit {
    SuccessTokenWithCallback public token;
    SuccessTokenBankWithCallback public bank;
    uint256 public attackCount;
    
    constructor(address _token, address _bank) {
        token = SuccessTokenWithCallback(_token);
        bank = SuccessTokenBankWithCallback(_bank);
    }
    
    function attack() external {
        // 先授权
        token.approve(address(bank), type(uint256).max);
        // 然后存款触发重入
        bank.deposit(100 * 10 ** token.decimals());
    }
    
    function onTransferReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        attackCount++;
        if (attackCount == 1) {
            // 第一次回调时尝试重入存款
            bank.deposit(50 * 10 ** token.decimals());
        }
        
        return bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
    }
}
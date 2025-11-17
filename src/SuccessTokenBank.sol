// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SuccessToken.sol";

/**
 * @title SuccessTokenBank
 * @dev 支持SuccessToken存取操作的银行合约
 */
contract SuccessTokenBank {
    // SuccessToken合约实例
    SuccessToken public successToken;
    
    // 存储每个用户的存款余额
    mapping(address => uint256) public deposits;
    
    // 事件：存款
    event Deposited(address indexed user, uint256 amount);
    
    // 事件：取款
    event Withdrawn(address indexed user, uint256 amount);
    
    /**
     * @dev 构造函数，初始化SuccessToken合约地址
     * @param _tokenAddress SuccessToken合约地址
     */
    constructor(address _tokenAddress) {
        successToken = SuccessToken(_tokenAddress);
    }
    
    /**
     * @dev 存款函数
     * @param amount 存款数量
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            successToken.balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );
        
        // 从用户转账代币到银行合约
        require(
            successToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        
        // 更新存款余额
        deposits[msg.sender] += amount;
        
        emit Deposited(msg.sender, amount);
    }
    
    /**
     * @dev 取款函数
     * @param amount 取款数量
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient deposit balance");
        
        // 更新存款余额
        deposits[msg.sender] -= amount;
        
        // 从银行合约转账代币给用户
        require(
            successToken.transfer(msg.sender, amount),
            "Token transfer failed"
        );
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev 获取用户的存款余额
     * @param user 用户地址
     * @return 存款余额
     */
    function getDepositBalance(address user) external view returns (uint256) {
        return deposits[user];
    }
    
    /**
     * @dev 获取银行合约中的总存款量
     * @return 总存款量
     */
    function getTotalDeposits() external view returns (uint256) {
        return successToken.balanceOf(address(this));
    }
    
    /**
     * @dev 获取用户的SuccessToken余额（钱包中的余额，非存款余额）
     * @param user 用户地址
     * @return 代币余额
     */
    function getTokenBalance(address user) external view returns (uint256) {
        return successToken.balanceOf(user);
    }
}
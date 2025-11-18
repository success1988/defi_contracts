// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SuccessTokenWithCallback.sol";

/**
 * @title SuccessTokenBankWithCallback
 * @dev 支持转账回调自动存款的银行合约
 */
contract SuccessTokenBankWithCallback {
    SuccessTokenWithCallback public successToken;
    bool private _locked;
    
    // 存储每个用户的存款余额
    mapping(address => uint256) public deposits;


    
    // 事件
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event AutoDeposited(address indexed from, uint256 amount, bytes data);
    


    // 回调函数的选择器
    bytes4 private constant _TRANSFER_RECEIVED = bytes4(
        keccak256("onTransferReceived(address,address,uint256,bytes)")
    );
    
    constructor(address _tokenAddress) {
        successToken = SuccessTokenWithCallback(_tokenAddress);
    }
    
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    
    /**
     * @dev 转账回调函数 - 当SuccessToken转账到本合约时自动调用
     */
    function onTransferReceived(
        address operator,   // 执行转账的操作者
        address from,       // 转账发送者
        uint256 amount,     // 转账金额
        bytes calldata data // 附加数据
    ) external nonReentrant returns (bytes4) {
        // 确保只有SuccessToken可以调用这个函数
        require(msg.sender == address(successToken), "Only token can call");
        
        // 执行自动存款逻辑
        _autoDeposit(from, amount, data);
        
        // 返回正确的selector表示成功处理
        return _TRANSFER_RECEIVED;
    }
    
    /**
     * @dev 自动存款内部逻辑
     */
    function _autoDeposit(address from, uint256 amount, bytes memory data) internal {
        // 更新存款余额
        deposits[from] += amount;
        
        emit AutoDeposited(from, amount, data);
        emit Deposited(from, amount);
    }
    
    /**
     * @dev 传统存款函数（仍然支持）
     */
    function deposit(uint256 amount) external nonReentrant{
        require(amount > 0, "Amount must be greater than 0");
        require(
            successToken.balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );
        
        // 使用transferFrom存款
        require(
            successToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
    
    /**
     * @dev 取款函数
     */
    function withdraw(uint256 amount) external nonReentrant{
        require(amount > 0, "Amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient deposit balance");
        
        deposits[msg.sender] -= amount;
        
        require(
            successToken.transfer(msg.sender, amount),
            "Token transfer failed"
        );
        
        emit Withdrawn(msg.sender, amount);
    }
    
    
    // 视图函数
    function getDepositBalance(address user) external view returns (uint256) {
        return deposits[user];
    }
    
    function getTotalDeposits() external view returns (uint256) {
        return successToken.balanceOf(address(this));
    }
    
    function getTokenBalance(address user) external view returns (uint256) {
        return successToken.balanceOf(user);
    }

}
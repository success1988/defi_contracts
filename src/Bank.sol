// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    mapping(address => uint256) public balances;
    address public owner;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    error ContractInsufficientBalance();
    error NotOwner(address operator);

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        if(address(this).balance < _amount){
            revert ContractInsufficientBalance();
        }
        
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }
    
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 仅合约所有者可以提取所有资金（紧急情况）
    function emergencyWithdraw() public {
        if(msg.sender != owner){
            revert NotOwner(msg.sender);
        }
        payable(owner).transfer(address(this).balance);
    }
}
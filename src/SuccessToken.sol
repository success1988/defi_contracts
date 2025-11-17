// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SuccessToken
 * @dev 基于ERC20标准的自定义代币
 */
contract SuccessToken is ERC20, Ownable {
    
    /**
     * @dev 构造函数，初始化代币名称、符号和总供应量
     * @param initialSupply 初始供应量
     */
    constructor(uint256 initialSupply) ERC20("SuccessToken", "SST") Ownable(msg.sender){
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
    
    /**
     * @dev 铸造新代币（仅所有者可调用）
     * @param to 接收地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev 销毁代币
     * @param amount 销毁数量
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
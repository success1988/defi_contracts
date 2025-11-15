// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SuccessTokenWithCallback
 * @dev 支持转账回调的ERC20代币
 */
contract SuccessTokenWithCallback is ERC20, Ownable {

    // 转账回调事件
    event TransferWithCallback(address indexed from, address indexed to, uint256 value, bytes data);
    
    constructor(uint256 initialSupply) 
        ERC20("SuccessToken", "SST") 
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
    


    /**
     * @dev 带回调的转账函数
     * @param to 接收地址
     * @param amount 转账金额
     * @param data 回调数据
     */
    function transferAndCall(address to, uint256 amount, bytes calldata data) 
        external 
        returns (bool) 
    {
        // 先执行普通转账
        bool success = transfer(to, amount);
        require(success, "Transfer failed");
        
        // 如果接收方是合约，触发回调
        if (isContract(to)) {
            require(
                checkOnTransferReceived(msg.sender, to, amount, data),
                "Transfer callback failed"
            );
        }
        
        emit TransferWithCallback(msg.sender, to, amount, data);
        return true;
    }
    
    /**
     * @dev 带回调的transferFrom函数
     */
    function transferFromAndCall(
        address from,
        address to, 
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        // 先执行transferFrom
        bool success = transferFrom(from, to, amount);
        require(success, "TransferFrom failed");
        
        // 如果接收方是合约，触发回调
        if (isContract(to)) {
            require(
                checkOnTransferReceived(from, to, amount, data),
                "Transfer callback failed"
            );
        }
        
        emit TransferWithCallback(from, to, amount, data);
        return true;
    }
    
    /**
     * @dev 检查并执行接收方合约的回调
     */
    function checkOnTransferReceived(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) internal returns (bool) {
        // 尝试调用接收方合约的 onTransferReceived 函数
        (bool success, bytes memory returnData) = to.call(
            abi.encodeWithSelector(
                bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)")),
                msg.sender, // 操作者（可能是from，也可能是授权的spender）
                from,       // 发送者
                amount,     // 金额
                data        // 附加数据
            )
        );
        
        // 检查调用是否成功并且返回了正确的selector
        if (success && returnData.length > 0) {
            bytes4 returnValue = abi.decode(returnData, (bytes4));
            return returnValue == bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
        }
        
        return false;
    }
    
    /**
     * @dev 检查地址是否为合约
     */
    function isContract(address account) internal view returns (bool) {
        return to.code.length > 0;
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
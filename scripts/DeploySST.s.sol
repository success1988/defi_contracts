// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SuccessTokenWithCallback.sol";
import "../src/SuccessTokenBankWithCallback.sol";

contract DeploySSTScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署代币合约 https://sepolia.etherscan.io/address/0x80317e662c0799b5f5656f5207f883fb1d75ccc9
        uint256 initialSupply = 1000000; // 100万代币
        SuccessTokenWithCallback token = new SuccessTokenWithCallback(initialSupply);
        
        console.log("SuccessTokenWithCallback deployed at:", address(token));
        console.log("Initial supply:", initialSupply * 10 ** token.decimals());
        console.log("Deployer token balance:", token.balanceOf(deployer));
        
        // 部署银行合约 https://sepolia.etherscan.io/address/0x9612b0e2bab8e22d0c0fd670ef584a95128da8eb
        SuccessTokenBankWithCallback bank = new SuccessTokenBankWithCallback(address(token));
        
        console.log("SuccessTokenBankWithCallback deployed at:", address(bank));
        console.log("Bank token balance:", token.balanceOf(address(bank)));
        
        vm.stopBroadcast();
    }
}

// 带测试数据的部署脚本
contract DeploySSTWithTestData is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署代币合约
        SuccessTokenWithCallback token = new SuccessTokenWithCallback(1000000);
        
        // 部署银行合约
        SuccessTokenBankWithCallback bank = new SuccessTokenBankWithCallback(address(token));
        
        // 分配测试代币给一些测试地址
        address[3] memory testUsers = [
            address(0x100),
            address(0x200),
            address(0x300)
        ];
        
        for (uint i = 0; i < testUsers.length; i++) {
            token.transfer(testUsers[i], 1000 * 10 ** token.decimals());
        }
        
        vm.stopBroadcast();
        
        console.log("Deployment completed with test data:");
        console.log("Token:", address(token));
        console.log("Bank:", address(bank));
        for (uint i = 0; i < testUsers.length; i++) {
            console.log("Test user %s: %s - Balance: %s", i, testUsers[i], token.balanceOf(testUsers[i]));
        }
    }
}
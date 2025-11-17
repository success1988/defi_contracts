// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Bank.sol";

contract DeployBank is Script {
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        Bank bank = new Bank();
        
        console.log("Bank contract deployed at:", address(bank));
        
        vm.stopBroadcast();

        //https://sepolia.etherscan.io/address/0x908ca3122d7a64630dba441d958509d8fb5ca8e2
    }
}
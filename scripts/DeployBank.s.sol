// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
    }
}
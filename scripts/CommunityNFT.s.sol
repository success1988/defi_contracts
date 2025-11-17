// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CommunityNFT.sol";

contract DeployCommunityNFT is Script {
    function run() external {
        // 从环境变量获取私钥，或者使用默认的 Anvil 私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署 CommunityNFT 合约
        CommunityNFT nft = new CommunityNFT();
        
        vm.stopBroadcast();
        
        console.log("CommunityNFT deployed to:", address(nft));
        
        // 保存部署地址到文件，便于后续使用
        vm.writeJson(
            vm.toString(address(nft)), 
            "./deployment.json"
        );
    }
}

// 部署并初始化一些示例数据的脚本
contract DeployAndSetup is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying and setting up with account:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署合约
        CommunityNFT nft = new CommunityNFT();
        
        // 定义示例成员
        address[] memory members = new address[](3);
        members[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Anvil 第二个账户
        members[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Anvil 第三个账户
        members[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Anvil 第四个账户
        
        // 定义对应的元数据 URI
        string[] memory uris = new string[](3);
        uris[0] = "ipfs://QmExample1/metadata.json";
        uris[1] = "ipfs://QmExample2/metadata.json";
        uris[2] = "ipfs://QmExample3/metadata.json";
        
        // 批量铸造示例 NFT
        nft.batchMintNFTs(members, uris);
        
        vm.stopBroadcast();
        
        console.log("CommunityNFT deployed to:", address(nft));
        console.log("Minted 3 example NFTs for community members");
        
        // 验证铸造结果
        console.log("Member 1 NFT:", nft.ownerOf(0));
        console.log("Member 2 NFT:", nft.ownerOf(1));
        console.log("Member 3 NFT:", nft.ownerOf(2));
    }
}
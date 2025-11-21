// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./SuccessTokenWithCallback.sol";
import "./CommunityNFT.sol";

contract NFTMarket{

    //FT合约
    SuccessTokenWithCallback public successToken;
    //NFT合约
    CommunityNFT public communityNFT;

    // 存储每个上架的NFT的tokenId和对应的价格
    mapping(uint256 => uint256) public prices;

    // 回调函数的选择器
    bytes4 private constant _TRANSFER_RECEIVED = bytes4(
        keccak256("onTransferReceived(address,address,uint256,bytes)")
    );

    //上架事件
    event NFTOnSale(address indexed seller, uint256 indexed tokenId, uint256 price);
    //卖出事件
    event NFTSold(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 price);

    //构造函数
    constructor(address _tokenAddress, address _nftAddress) {
        successToken = SuccessTokenWithCallback(_tokenAddress);
        communityNFT = CommunityNFT(_nftAddress);
    }

    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    error PriceMustPositive();
    error NotOwner(address caller);
    error AlreadyOnSale(uint256 tokenId);
    error AlreadySold(uint256 tokenId);
    error NotApproved(uint256 tokenId);
    error InsufficientBalance(uint256 available, uint256 required);

    //上架NFT
    function list(uint256 tokenId, uint256 price) external returns (bool) {
        //校验price大于0
        if(price <= 0){
           revert PriceMustPositive();
        }

        //校验msg.sender是否持有该tokenId
        if(msg.sender != communityNFT.ownerOf(tokenId)){
           revert NotOwner(msg.sender);
        }

        //校验该tokenId是否已经上架, 对应的price大于0表示上架中
        if(prices[tokenId] > 0){
            revert AlreadyOnSale(tokenId);
        }
        
        //校验是否授权给了当前合约
        address approvedAddr = communityNFT.getApproved(tokenId);
        if(approvedAddr != address(this)){
            revert NotApproved(tokenId);
        }
     
        //设置该NFT的售价
        prices[tokenId] = price;

        //触发上架事件
        emit NFTOnSale(msg.sender, tokenId, price);
        return true;
    } 


    //购买NFT： 钱从msg.sender转移到tokenId的持有者, NFT的owner从持有者变更为msg.sender
    function buyNFT(uint256 tokenId) external returns (bool) {
        uint256 nftPrice = prices[tokenId];
        if(nftPrice == 0){
            revert AlreadySold(tokenId);
        }

        //校验msg.sender的账户余额是否大于等于NFT价格
        uint256 senderBalance = successToken.balanceOf(msg.sender);
        if(senderBalance < nftPrice){
            revert InsufficientBalance(senderBalance, nftPrice);
        }

        //查询tokenId的持有者,并向其转账
        address holder = communityNFT.ownerOf(tokenId);
        successToken.transfer(holder, nftPrice);
        
        address approvedAddr = communityNFT.getApproved(tokenId);
        if(approvedAddr != address(this)){
            revert NotApproved(tokenId);
        }
        //当前合约将该NFT转移给买家
        communityNFT.safeTransferFrom(holder, msg.sender, tokenId);
        //将当前NFT下架
        delete prices[tokenId]；

        //触发卖出事件
        emit NFTSold(msg.sender, holder, tokenId, nftPrice);
        return true;
    }

    /**
     * @dev 转账回调函数 - 当SuccessToken转账到本合约时自动调用
     */
    function onTransferReceived(
        address operator,   // 执行转账的操作者
        address from,       // 转账发送者
        uint256 amount,     // 转账金额
        bytes calldata data // 附加数据, 约定为NFT的tokenId
    ) external nonReentrant returns (bytes4) {
        // 确保只有SuccessToken可以调用这个函数
        require(msg.sender == address(successToken), "Only token can call");
        
        // 执行自动购买NFT的逻辑
        uint256 tokenId = abi.decode(data, (uint256));
        uint256 nftPrice = prices[tokenId];
        if(amount < nftPrice){
            revert InsufficientBalance(amount, nftPrice);
        }
        
        address approvedAddr = communityNFT.getApproved(tokenId);
        if(approvedAddr != address(this)){
            revert NotApproved(tokenId);
        }
        
        address holder = communityNFT.ownerOf(tokenId);
        //当前合约将该NFT转移给买家
        communityNFT.safeTransferFrom(holder, from, tokenId);
        //将当前NFT下架
        delete prices[tokenId]；

        //触发卖出事件
        emit NFTSold(from, holder, tokenId, nftPrice);
        // 返回正确的selector表示成功处理
        return _TRANSFER_RECEIVED;
    }
}
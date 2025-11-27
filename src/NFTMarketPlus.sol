// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTMarketPlus is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;   // 🔐 关键：SafeERC20 套件

    /* ── 新增构造函数 ── */
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address paymentToken;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address paymentToken
    );
    event NFTPurchased(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address paymentToken
    );
    event ListingCancelled(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    modifier onlyNFTOwner(address nftContract, uint256 tokenId) {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        _;
    }
    modifier isListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].seller != address(0), "Not listed");
        _;
    }

    /**
     * 传统上架：卖家先把 NFT 授权给市场，再调用 listNFT
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    ) external onlyNFTOwner(nftContract, tokenId) {
        require(price > 0, "Price must be greater than zero");
        require(paymentToken != address(0), "Invalid payment token");

        // 把 NFT 托管到合约
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: paymentToken
        });

        emit NFTListed(msg.sender, nftContract, tokenId, price, paymentToken);
    }

     /**
     * 推模式上架回调
     * data = abi.encode(uint256 price, address paymentToken)
     * operator 是 “执行者”，from 是 “原持有者/卖家”；这里业务只用后者，所以注释掉前者

     用户侧的示例：   
        # 1. 构造 data
        price=1000000000000000000          # 1 ether
        token=0xMockERC20
        data=$(cast abi-encode "f(uint256,address)" $price $token)

        # 2. 一步上架
        cast send $nft "safeTransferFrom(address,address,uint256,bytes)" \
            $seller $market 1 $data --private-key $pk

     */
    function onERC721Received(
        address, /* operator */
        address from,          // 卖家
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(data.length == 64, "bad data length"); // 2 × 32 bytes

        (uint256 price, address paymentToken) = abi.decode(
            data,
            (uint256, address)
        );
        require(price > 0, "price zero");
        require(paymentToken != address(0), "token zero");

        address nftContract = msg.sender; // 谁转进来就是哪个 NFT

        // 直接写入挂单
        listings[nftContract][tokenId] = Listing({
            seller: from,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            paymentToken: paymentToken
        });

        emit NFTListed(from, nftContract, tokenId, price, paymentToken);

        return this.onERC721Received.selector;
    }

    /**
     * 购买：使用 SafeERC20.safeTransferFrom 替代裸 transferFrom
     */
    function buyNFT(address nftContract, uint256 tokenId)
        external
        nonReentrant
        isListed(nftContract, tokenId)
    {
        Listing memory listing = listings[nftContract][tokenId];

        // 1. 买家付款（SafeERC20 会 revert 如果失败）
        IERC20(listing.paymentToken).safeTransferFrom(
            msg.sender,
            listing.seller,
            listing.price
        );

        // 2. 删除挂单
        delete listings[nftContract][tokenId];

        // 3. 把 NFT 给买家
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit NFTPurchased(
            msg.sender,
            nftContract,
            tokenId,
            listing.price,
            listing.paymentToken
        );
    }

    /**
     * 卖家取消上架
     */
    function cancelListing(address nftContract, uint256 tokenId)
        external
        isListed(nftContract, tokenId)
    {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Not seller");

        delete listings[nftContract][tokenId];
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    /**
     * 紧急提取误转 NFT（仅管理员）
     */
    function emergencyWithdrawNFT(address nftContract, uint256 tokenId)
        external
        onlyOwner
    {
        IERC721(nftContract).transferFrom(address(this), owner(), tokenId);
    }
}
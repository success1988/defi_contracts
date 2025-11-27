// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "../src/NFTMarketPlus.sol";

/* ------------------ Mock 合约 ------------------ */
contract MockERC721 is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}
    function mint(address to, uint256 id) external {
        _mint(to, id);
    }
}

contract MockERC20 is ERC20 {
    constructor() ERC20("MockUSDC", "MUSDC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

/* 税币：转账扣 5% 且返回 true */
contract TaxToken is ERC20 {
    constructor() ERC20("TaxToken", "TAX") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 tax = (amount * 5) / 100;
        uint256 receiveAmount = amount - tax;
        super.transferFrom(from, to, receiveAmount);
        super.transferFrom(from, address(0), tax); // 烧税
        return true;
    }
}

/* ------------------ 测试主体 ------------------ */
contract NFTMarketPlusTest is Test {
    NFTMarketPlus market;
    MockERC721 nft;
    MockERC20  usd;


    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address relayer = makeAddr("relayer"); // 第三方 operator

    function setUp() external {
        market = new NFTMarketPlus(address(this));
        nft = new MockERC721();
        usd = new MockERC20();

        nft.mint(alice, 1);
        nft.mint(alice, 2);
        //usd.transfer(bob, 10_000 * 10 ** 18);
        deal(address(usd), bob, 10_000 * 10 ** 18);
    }

    function invokeList() internal{
        vm.prank(alice);
        nft.setApprovalForAll(address(market), true);

        vm.prank(alice);
        market.listNFT(address(nft), 1, 100 * 10 ** 18, address(usd));

        (address seller,,,,) = market.listings(address(nft), 1);
        assertEq(seller, alice);
        assertEq(nft.ownerOf(1), address(market));
    }

    /* ========== 传统上架 ========== */
    function testList() external {
        invokeList();
    }

    /* ========== 推模式上架（回调） ========== */
    function testListByCallback() external {
        bytes memory data = abi.encode(200 * 10 ** 18, address(usd));

        vm.prank(alice);
        nft.safeTransferFrom(alice, address(market), 2, data);

        (address seller,,,,) = market.listings(address(nft), 2);
        assertEq(seller, alice);
        assertEq(nft.ownerOf(2), address(market));
    }

    /* ========== 第三方 operator 代上架 ========== */
    function testListByOperator() external {
        // alice 授权给 relayer
        vm.prank(alice);
        nft.setApprovalForAll(relayer, true);

        bytes memory data = abi.encode(300 * 10 ** 18, address(usd));

        // relayer 作为 operator 帮 alice 上架
        vm.prank(relayer);
        nft.safeTransferFrom(alice, address(market), 1, data);

        (address seller,,,,) = market.listings(address(nft), 1);
        assertEq(seller, alice);     // 卖家仍是 alice
        assertEq(nft.ownerOf(1), address(market));
    }

    /* ========== 购买 ========== */
    function testBuy() external {
        // 先用传统上架
        invokeList();

        vm.prank(bob);
        usd.approve(address(market), 100 * 10 ** 18);

        vm.prank(bob);
        market.buyNFT(address(nft), 1);

        assertEq(nft.ownerOf(1), bob);
        assertEq(usd.balanceOf(alice), 100 * 10 ** 18);
    }

    /* ========== 取消上架 ========== */
    function testCancel() external {
        invokeList();

        vm.prank(alice);
        market.cancelListing(address(nft), 1);

        assertEq(nft.ownerOf(1), alice);
        (address seller,,,,) = market.listings(address(nft), 1);
        assertEq(seller, address(0));
    }

    /* ========== SafeERC20 税币失败 ========== */
    function testBuyTaxTokenFail() external {
        TaxToken tax = new TaxToken();
        tax.mint(bob, 200 * 10 ** 18);

        // 用税币上架
        vm.prank(alice);
        nft.setApprovalForAll(address(market), true);
        vm.prank(alice);
        market.listNFT(address(nft), 1, 100 * 10 ** 18, address(tax));

        // bob 授权足够，但到账不足 100，SafeERC20 会 revert
        vm.prank(bob);
        tax.approve(address(market), type(uint256).max);

        vm.expectRevert();
        vm.prank(bob);
        market.buyNFT(address(nft), 1);
    }
}
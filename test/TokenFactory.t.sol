// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";


contract TokenFactoryTest is Test {
    TokenFactory public factory;
    uint256 mainnetFork;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router01 router;
    Token public tokenImplemetation;

    function setUp() public {
        tokenImplemetation = new Token();
        factory = new TokenFactory(address(tokenImplemetation), 500000); // 1/2
        mainnetFork = vm.createSelectFork("mainnet");
        uniswapFactory = IUniswapV2Factory(factory.UNISWAP_V2_FACTORY());
        router = IUniswapV2Router01(factory.UNISWAP_V2_ROUTER());
    }

    function test_CreateToken() public {
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        assert(tokenAddress != address(0));
        assert(factory.tokens(tokenAddress) == TokenFactory.TokenState.FUNDING);

        Token token = Token(tokenAddress);
        assertEq(token.name(), "MyFirstToken");
        assertEq(token.symbol(), "MFT");
        assert(token.totalSupply() == 1);
    }

    function test_CalculateBuyReturn() public {
        // 1 ether, 0.8B / 20 = 40M
        uint256 tokenAmountBuyed = factory.calculateBuyReturn(1 ether);
        assert(tokenAmountBuyed == 40_000_000 ether);
        uint256 tokenAmountAllBuyed = factory.calculateBuyReturn(20 ether);
        assert(tokenAmountAllBuyed == 0.8 * 10 ** 9 * 1 ether);
    }

    function test_Buy() public {
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        Token token = Token(tokenAddress);

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);
        // assert(token.balanceOf(alice) == 40_000_000 ether);

        factory.buy{value: 18 ether}(tokenAddress);
        // assert(token.balanceOf(alice) == 760_000_000 ether); // 19 ETH
        vm.stopPrank();
    }

    function test_BuyForked() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        Token token = Token(tokenAddress);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);
        // assert(token.balanceOf(alice) == 40_000_000 ether);

        factory.buy{value: 19 ether}(tokenAddress);
        // assert(token.balanceOf(alice) == 800_000_000 ether); // 20 ETH
        assert(factory.tokens(tokenAddress) == TokenFactory.TokenState.TRADING);
        // check of pair exists
        assert(
            uniswapFactory.getPair(tokenAddress, router.WETH()) != address(0)
        );
        // check liquity
        address poolAddress = uniswapFactory.getPair(tokenAddress, router.WETH());
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        assert(pool.balanceOf(address(0)) > 1000); // sqrt(20ether * 200M ether)
        assert(pool.balanceOf(address(factory)) == 0);
        vm.stopPrank();
    }

    function test_CalculateSellReturn() public {
        // 1 ether, 0.8B / 20 = 40M
        uint256 ethAmountReceived = factory.calculateSellReturn(
            40_000_000 ether
        );
        assert(ethAmountReceived == 1 ether);
        uint256 ethAmountAllReceived = factory.calculateSellReturn(
            0.8 * 10 ** 9 * 1 ether
        );
        assert(ethAmountAllReceived == 20 ether);
    }

    function test_Sell() public {
        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        Token token = Token(tokenAddress);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);
        factory.sell(tokenAddress, 1_000_000);
        // assert(token.balanceOf(alice) == 30_000_000 ether);
        factory.sell(tokenAddress, 1_000_000);
        assert(token.balanceOf(alice) == 993443601);
        vm.stopPrank();
    }
}

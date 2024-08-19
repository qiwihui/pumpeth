// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router01 router;
    Token public tokenImplemetation;

    function setUp() public {
        tokenImplemetation = new Token();
        factory = new TokenFactory(address(tokenImplemetation)); // 1/2
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
        assertEq(token.owner(), address(factory));
    }

    function test_Buy() public {
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        Token token = Token(tokenAddress);

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);
        assert(token.balanceOf(alice) > 0);
        factory.buy{value: 18 ether}(tokenAddress);
        vm.stopPrank();
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
        assert(token.balanceOf(alice) == 59472943757613679998000000);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {FixedPointMathLib} from "@solady-0.0.233/src/utils/FixedPointMathLib.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";

contract TokenFactoryForkedTest is Test {
    TokenFactory public factory;
    uint256 mainnetFork;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router01 router;
    Token public tokenImplemetation;

    function setUp() public {
        mainnetFork = vm.createSelectFork("mainnet");

        tokenImplemetation = new Token();
        factory = new TokenFactory(address(tokenImplemetation));
        uniswapFactory = IUniswapV2Factory(factory.UNISWAP_V2_FACTORY());
        router = IUniswapV2Router01(factory.UNISWAP_V2_ROUTER());
    }

    function test_ForkedBuy() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        Token token = Token(tokenAddress);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);
        assert(token.balanceOf(alice) == 59472943757613680000000000);
        factory.buy{value: 25 ether}(tokenAddress);
        assert(token.balanceOf(alice) == 799999999977117981000000000);
        assert(address(alice).balance > 9 ether); // substract some gas

        assert(factory.tokens(tokenAddress) == TokenFactory.TokenState.TRADING);
        assert(factory.collateral(tokenAddress) == 0);

        // check of pair exists
        assert(
            uniswapFactory.getPair(tokenAddress, router.WETH()) != address(0)
        );
        // check liquity
        address poolAddress = uniswapFactory.getPair(
            tokenAddress,
            router.WETH()
        );
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        assert(
            pool.balanceOf(address(0)) ==
                FixedPointMathLib.sqrt(20 ether * 200000000 ether)
        ); // sqrt(20ether * 200M ether)
        assert(pool.balanceOf(address(factory)) == 0);
        vm.stopPrank();
    }

    function test_ForkedSell() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");

        vm.startPrank(alice);
        vm.expectRevert();
        factory.sell(tokenAddress, 1);

        factory.buy{value: 1 ether}(tokenAddress);
        factory.sell(tokenAddress, 59472943757613680000000000);

        factory.buy{value: 19 ether - 1}(tokenAddress);
        factory.sell(tokenAddress, 1);

        // all buyed, revert when selling
        factory.buy{value: 1 ether}(tokenAddress);
        vm.expectRevert();
        factory.sell(tokenAddress, 40_000_000 ether);
        vm.stopPrank();
    }
}

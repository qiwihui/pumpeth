// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {FixedPointMathLib} from "@solady-0.0.233/src/utils/FixedPointMathLib.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract TokenFactoryForkedTest is Test {
    TokenFactory public factory;
    uint256 mainnetFork;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router01 router;
    Token public tokenImplemetation;
    BondingCurve public bondingCurve;

    address public constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        mainnetFork = vm.createSelectFork("mainnet");
        bondingCurve = new BondingCurve(16319324419, 1000000000);
        tokenImplemetation = new Token();
        factory = new TokenFactory(
            address(tokenImplemetation),
            UNISWAP_V2_ROUTER,
            UNISWAP_V2_FACTORY,
            address(bondingCurve),
            100
        );
        uniswapFactory = IUniswapV2Factory(factory.uniswapV2Factory());
        router = IUniswapV2Router01(factory.uniswapV2Router());
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
        assert(token.balanceOf(alice) == 58895387276865135000000000);
        vm.expectEmit(true, false, false, false);
        emit TokenFactory.TokenLiqudityAdded(tokenAddress, 1);
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

        factory.buy{value: 1 ether}(tokenAddress);
        factory.sell(tokenAddress, 58901107293165284000000000);

        factory.buy{value: 25 ether}(tokenAddress);
        factory.sell(tokenAddress, 100);

        // all buyed, revert when selling
        factory.buy{value: 1 ether}(tokenAddress);
        vm.expectRevert();
        factory.sell(tokenAddress, 40_000_000 ether);
        vm.stopPrank();
    }

    function test_ForkedSellEmpty() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        address alice = makeAddr("bob");
        vm.deal(alice, 30 ether);
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");

        vm.startPrank(alice);

        vm.expectRevert();
        factory.sell(tokenAddress, 1);

        vm.stopPrank();
    }
}

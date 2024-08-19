// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;
    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router01 router;
    Token public tokenImplemetation;
    BondingCurve public bondingCurve;
    uint256 feePercent = 100;

    address public constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        tokenImplemetation = new Token();
        bondingCurve = new BondingCurve(16319324419, 1000000000);
        factory = new TokenFactory(
            address(tokenImplemetation),
            UNISWAP_V2_ROUTER,
            UNISWAP_V2_FACTORY,
            address(bondingCurve),
            feePercent
        );
        uniswapFactory = IUniswapV2Factory(factory.uniswapV2Factory());
        router = IUniswapV2Router01(factory.uniswapV2Router());
    }

    function test_CreateToken() public {
        vm.expectEmit(false, false, false, false, address(factory));
        emit TokenFactory.TokenCreated(address(1), 1);
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
        assert(
            factory.fee() == (19 ether * feePercent) / factory.FEE_DENOMINATOR()
        );
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
        factory.sell(tokenAddress, 1_000_000);
        assert(token.balanceOf(alice) == 58895387276865134998000000);
        vm.stopPrank();
    }

    function test_claimFee() public {
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");

        address alice = makeAddr("alice");
        vm.deal(alice, 30 ether);

        vm.startPrank(alice);
        factory.buy{value: 1 ether}(tokenAddress);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        factory.claimFee();
        assert(
            factory.fee() == (1 ether * feePercent) / factory.FEE_DENOMINATOR()
        );
        vm.stopPrank();
        factory.claimFee();
        assert(factory.fee() == 0);
    }

    receive() external payable {}
}

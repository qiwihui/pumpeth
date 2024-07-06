// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";

contract TokenFactoryTest is Test {
    TokenFactory public factory;

    function setUp() public {
        factory = new TokenFactory();
    }

    function test_CreateToken() public {
        address tokenAddress = factory.createToken("MyFirstToken", "MFT");
        assert(tokenAddress != address(0));

        Token token = Token(tokenAddress);
        assert(token.totalSupply() == factory.INITIAL_SUPPLY());
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
        assert(token.balanceOf(alice) == 40_000_000 ether);

        factory.buy{value: 18 ether}(tokenAddress);
        assert(token.balanceOf(alice) == 760_000_000 ether); // 19 ETH
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
        factory.sell(tokenAddress, 10_000_000 ether);
        assert(token.balanceOf(alice) == 30_000_000 ether);
        factory.sell(tokenAddress, 30_000_000 ether);
        assert(token.balanceOf(alice) == 0);
        vm.stopPrank();
    }
}

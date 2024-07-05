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
}

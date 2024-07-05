// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Token} from "./Token.sol";

contract TokenFactory {
    uint256 public constant MAX_SUPPLY = 10 ** 9 * 10 ** 18;
    uint256 public constant INITIAL_SUPPLY = (MAX_SUPPLY * 1) / 5;
    uint256 public constant FUNDING_SUPPLY = (MAX_SUPPLY * 4) / 5;
    mapping(address => bool) tokens;

    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        Token token = new Token(name, symbol, INITIAL_SUPPLY);
        tokens[address(token)] = true;
        return address(token);
    }
}

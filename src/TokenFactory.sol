// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Token} from "./Token.sol";

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";

contract TokenFactory {
    uint256 public constant MAX_SUPPLY = 10 ** 9 * 10 ** 18;
    uint256 public constant INITIAL_SUPPLY = (MAX_SUPPLY * 1) / 5;
    uint256 public constant FUNDING_SUPPLY = (MAX_SUPPLY * 4) / 5;
    uint256 public constant FUNDING_GOAL = 20 ether;
    mapping(address => bool) tokens;
    mapping(address => uint256) collateral;

    address public constant UNISWAP_V2_FACTORY =
        0xB7f907f7A9eBC822a80BD25E224be42Ce0A698A0;
    address public constant UNISWAP_V2_ROUTER =
        0x425141165d3DE9FEC831896C016617a52363b687;

    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        Token token = new Token(name, symbol, INITIAL_SUPPLY);
        tokens[address(token)] = true;
        return address(token);
    }

    function buy(address tokenAddress) external payable {
        require(tokens[tokenAddress], "Token not found");
        require(msg.value > 0, "ETH not enough");
        uint256 amount = calculateBuyReturn(msg.value);
        Token token = Token(tokenAddress);
        uint256 availableSupply = MAX_SUPPLY - token.totalSupply();
        require(amount <= availableSupply, "Token not enough");
        collateral[tokenAddress] += msg.value;
        token.mint(msg.sender, amount);
        // when reach FUNDING_GOAL
        if (collateral[tokenAddress] >= FUNDING_GOAL) {
            address pair = createLiquilityPool(tokenAddress);
            uint256 liquidity = addLiquidity(
                tokenAddress,
                INITIAL_SUPPLY,
                collateral[tokenAddress]
            );
            burnLiquidityToken(pair, liquidity);
            collateral[tokenAddress] = 0;
        }
    }

    function sell(address tokenAddress, uint256 amount) external {
        require(tokens[tokenAddress], "Token not found");
        require(amount > 0, "Token not enough");
        Token token = Token(tokenAddress);
        token.burn(msg.sender, amount);
        uint256 receivedETH = calculateSellReturn(amount);
        collateral[tokenAddress] -= receivedETH;
        // send ether
        (bool success, ) = msg.sender.call{value: receivedETH}(new bytes(0));
        require(success, "ETH send failed");
    }

    // TODO: Bonding curve
    function calculateBuyReturn(
        uint256 ethAmount
    ) public pure returns (uint256) {
        return (ethAmount * FUNDING_SUPPLY) / FUNDING_GOAL;
    }

    // TODO: Bonding curve
    function calculateSellReturn(
        uint256 tokenAmount
    ) public pure returns (uint256) {
        return (tokenAmount * FUNDING_GOAL) / FUNDING_SUPPLY;
    }

    function createLiquilityPool(
        address tokenAddress
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
        IUniswapV2Router01 router = IUniswapV2Router01(UNISWAP_V2_ROUTER);

        address pair = factory.createPair(tokenAddress, router.WETH());
        return pair;
    }

    function addLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal returns (uint256) {
        Token token = Token(tokenAddress);
        IUniswapV2Router01 router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
        token.approve(UNISWAP_V2_ROUTER, tokenAmount);
        (, , uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );
        return liquidity;
    }

    function burnLiquidityToken(address pair, uint256 liquidity) internal {
        IUniswapV2Pair pool = IUniswapV2Pair(pair);
        pool.transfer(address(0), liquidity);
    }
}

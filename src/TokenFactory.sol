// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Token} from "./Token.sol";

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {Clones} from "@openzeppelin-contracts-5.0.2/proxy/Clones.sol";
import {BancorFormula} from "./BancorFormula.sol";

contract TokenFactory is BancorFormula {
    enum TokenState {
        NOT_CREATED,
        FUNDING,
        TRADING
    }
    uint256 public constant MAX_SUPPLY = 10 ** 9 * 10 ** 18;
    uint256 public constant INITIAL_SUPPLY = (MAX_SUPPLY * 1) / 5;
    uint256 public constant FUNDING_SUPPLY = (MAX_SUPPLY * 4) / 5;
    uint256 public constant FUNDING_GOAL = 20 ether;
    mapping(address => TokenState) public tokens;
    mapping(address => uint256) public collateral;
    address public immutable tokenImplementation;

    uint32 reserveRatio;

    address public constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(address _tokenImplementation, uint32 _reserveRatio) {
        tokenImplementation = _tokenImplementation;
        reserveRatio = _reserveRatio;
    }

    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        address tokenAddress = Clones.clone(tokenImplementation);
        Token token = Token(tokenAddress);
        token.initialize(name, symbol, 1);
        tokens[tokenAddress] = TokenState.FUNDING;
        collateral[tokenAddress] = 1;
        return tokenAddress;
    }

    function buy(address tokenAddress) external payable {
        require(tokens[tokenAddress] == TokenState.FUNDING, "Token not found");
        require(msg.value > 0, "ETH not enough");
        Token token = Token(tokenAddress);
        // uint256 amount = calculateBuyReturn(msg.value);
        uint256 amount = calculatePurchaseReturn(
            token.totalSupply(),
            collateral[tokenAddress],
            reserveRatio,
            msg.value
        );
        uint256 availableSupply = MAX_SUPPLY - token.totalSupply();
        require(amount <= availableSupply, "Token not enough");
        collateral[tokenAddress] += msg.value;
        token.mint(msg.sender, amount);
        // when reach FUNDING_GOAL
        if (collateral[tokenAddress] >= FUNDING_GOAL) {
            token.mint(address(this), INITIAL_SUPPLY);
            address pair = createLiquilityPool(tokenAddress);
            uint256 liquidity = addLiquidity(
                tokenAddress,
                INITIAL_SUPPLY,
                collateral[tokenAddress] - 1
            );
            burnLiquidityToken(pair, liquidity);
            collateral[tokenAddress] = 0;
            tokens[tokenAddress] = TokenState.TRADING;
        }
    }

    function sell(address tokenAddress, uint256 amount) external {
        require(tokens[tokenAddress] == TokenState.FUNDING, "Token not found");
        require(amount > 0, "Token not enough");
        Token token = Token(tokenAddress);
        token.burn(msg.sender, amount);
        // uint256 receivedETH = calculateSellReturn(amount);
        uint256 receivedETH = calculateSaleReturn(
            token.totalSupply(),
            collateral[tokenAddress],
            reserveRatio,
            amount
        );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IUniswapV2Factory} from "@uniswap-v2-core-1.0.1/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router01} from "@uniswap-v2-periphery-1.1.0-beta.0/contracts/interfaces/IUniswapV2Router01.sol";
import {Clones} from "@openzeppelin-contracts-5.0.2/proxy/Clones.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts-5.0.2/utils/ReentrancyGuard.sol";
import "@openzeppelin-contracts-5.0.2/token/ERC20/utils/SafeERC20.sol";
import {BondingCurve} from "./BondingCurve.sol";
import {Token} from "./Token.sol";

contract TokenFactory is ReentrancyGuard {
    enum TokenState {
        NOT_CREATED,
        FUNDING,
        TRADING
    }
    uint256 public constant MAX_SUPPLY = 10 ** 9 * 1 ether; // 1 Billion
    uint256 public constant INITIAL_SUPPLY = (MAX_SUPPLY * 1) / 5;
    uint256 public constant FUNDING_SUPPLY = (MAX_SUPPLY * 4) / 5;
    uint256 public constant FUNDING_GOAL = 20 ether;

    mapping(address => TokenState) public tokens;
    mapping(address => uint256) public collateral;
    address public immutable tokenImplementation;
    address public uniswapV2Router;
    address public uniswapV2Factory;
    BondingCurve public bondingCurve;

    constructor(
        address _tokenImplementation,
        address _uniswapV2Router,
        address _uniswapV2Factory,
        address _bondingCurveAddr
    ) {
        tokenImplementation = _tokenImplementation;
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = _uniswapV2Factory;
        bondingCurve = BondingCurve(_bondingCurveAddr);
    }

    // Token functions
    function createToken(
        string memory name,
        string memory symbol
    ) public returns (address) {
        address tokenAddress = Clones.clone(tokenImplementation);
        Token token = Token(tokenAddress);
        token.initialize(name, symbol);
        tokens[tokenAddress] = TokenState.FUNDING;
        return tokenAddress;
    }

    function buy(address tokenAddress) public payable nonReentrant {
        require(tokens[tokenAddress] == TokenState.FUNDING, "Token not found");
        require(msg.value > 0, "ETH not enough");
        Token token = Token(tokenAddress);
        uint256 valueToBuy = msg.value;
        // TODO: convert collateral[tokenAddress] to memory
        if (collateral[tokenAddress] + valueToBuy > FUNDING_GOAL) {
            valueToBuy = FUNDING_GOAL - collateral[tokenAddress];
        }
        uint256 amount = bondingCurve.getAmountOut(
            token.totalSupply(),
            valueToBuy
        );
        uint256 availableSupply = FUNDING_SUPPLY - token.totalSupply();
        require(amount <= availableSupply, "Token not enough");
        collateral[tokenAddress] += valueToBuy;
        token.mint(msg.sender, amount);
        // when reach FUNDING_GOAL
        if (collateral[tokenAddress] >= FUNDING_GOAL) {
            token.mint(address(this), INITIAL_SUPPLY);
            address pair = createLiquilityPool(tokenAddress);
            uint256 liquidity = addLiquidity(
                tokenAddress,
                INITIAL_SUPPLY,
                collateral[tokenAddress]
            );
            burnLiquidityToken(pair, liquidity);
            collateral[tokenAddress] = 0;
            tokens[tokenAddress] = TokenState.TRADING;
        }
        if (valueToBuy < msg.value) {
            (bool success, ) = msg.sender.call{value: msg.value - valueToBuy}(
                new bytes(0)
            );
            require(success, "ETH send failed");
        }
    }

    function sell(address tokenAddress, uint256 amount) public nonReentrant {
        require(
            tokens[tokenAddress] == TokenState.FUNDING,
            "Token is not funding"
        );
        require(amount > 0, "Amount should be greater than zero");
        Token token = Token(tokenAddress);
        uint256 receivedETH = bondingCurve.getFundsReceived(
            token.totalSupply(),
            amount
        );
        token.burn(msg.sender, amount);
        collateral[tokenAddress] -= receivedETH;
        // send ether
        //slither-disable-next-line arbitrary-send-eth
        (bool success, ) = msg.sender.call{value: receivedETH}(new bytes(0));
        require(success, "ETH send failed");
    }

    function createLiquilityPool(
        address tokenAddress
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Factory);
        IUniswapV2Router01 router = IUniswapV2Router01(uniswapV2Router);

        address pair = factory.createPair(tokenAddress, router.WETH());
        return pair;
    }

    function addLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal returns (uint256) {
        Token token = Token(tokenAddress);
        IUniswapV2Router01 router = IUniswapV2Router01(uniswapV2Router);
        token.approve(uniswapV2Router, tokenAmount);
        //slither-disable-next-line arbitrary-send-eth
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
        SafeERC20.safeTransfer(IERC20(pair), address(0), liquidity);
    }
}

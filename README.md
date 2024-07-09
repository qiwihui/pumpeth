## pump eth

1. 创建代币
2. 购买代币
3. 卖出代币

```solidity
contract Token is ERC20 {}

contract TokenFactory
- createToken(string name, string symbol)
    - new Token
    - initial_supply

- buy(address tokenAddress) payable
    - calculateBuyReturn()
    - uniswap:
        - createLiquilityPool()
        - addLiquidity()
        - burnLiquidityToken()

- sell(address tokenAddress, uint256 amount)
    - calculateSellReturn()
    - transfer
```

TODO:

1. [x] check token state
2. [ ] Bonding Curve
3. [ ] Fork sepolia, test uniswap
4. [ ] mini proxy

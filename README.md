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
2. [x] Fork mainnet, test uniswap
3. [x] minimal proxy
4. [ ] Bonding Curve

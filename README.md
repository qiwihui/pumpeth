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

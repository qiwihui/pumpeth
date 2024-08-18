// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC20Upgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC20/ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable {
    address public owner;

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        owner = msg.sender;
        __ERC20_init(name, symbol);
    }

    function mint(address to, uint256 amount) public {
        require(owner == msg.sender, "Only owner");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public {
        require(owner == msg.sender, "Only owner");
        _burn(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {ERC20Upgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable {
    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public onlyOwner {
        _burn(to, amount);
    }
}

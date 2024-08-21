// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {Token} from "../src/Token.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // sepolia
        address UNISWAP_V2_FACTORY = 0x7E0987E5b3a30e3f2828572Bb659A548460a3003;
        address UNISWAP_V2_ROUTER = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;

        vm.startBroadcast(deployerPrivateKey);
        // BondingCurve bondingCurve = new BondingCurve(16319324419, 1000000000); // 20 eth

        new BondingCurve(505940703, 2000000000); // 1 eth
        new BondingCurve(646519142, 1500000000); // 1 eth
        BondingCurve bondingCurve = new BondingCurve(815966221, 1000000000); // 1 eth
        // deploy token impl
        Token tokenImplemetation = new Token();
        new TokenFactory(
            address(tokenImplemetation),
            UNISWAP_V2_ROUTER,
            UNISWAP_V2_FACTORY,
            address(bondingCurve),
            100
        );
        vm.stopBroadcast();
    }
}

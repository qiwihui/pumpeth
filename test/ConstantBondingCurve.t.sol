// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ConstantBondingCurve} from "../src/ConstantBondingCurve.sol";

contract ConstantBondingCurveTest is Test {
    ConstantBondingCurve bondingCurve;

    function setUp() public {
        bondingCurve = new ConstantBondingCurve();
    }

    function test_CalculateBuyReturn() public {
        // 1 ether, 0.8B / 20 = 40M
        uint256 tokenAmountBuyed = bondingCurve.calculateBuyReturn(1 ether);
        assert(tokenAmountBuyed == 40_000_000 ether);
        uint256 tokenAmountAllBuyed = bondingCurve.calculateBuyReturn(20 ether);
        assert(tokenAmountAllBuyed == 0.8 * 10 ** 9 * 1 ether);
    }

    function test_CalculateSellReturn() public {
        // 1 ether, 0.8B / 20 = 40M
        uint256 ethAmountReceived = bondingCurve.calculateSellReturn(
            40_000_000 ether
        );
        assert(ethAmountReceived == 1 ether);
        uint256 ethAmountAllReceived = bondingCurve.calculateSellReturn(
            0.8 * 10 ** 9 * 1 ether
        );
        assert(ethAmountAllReceived == 20 ether);
    }
}

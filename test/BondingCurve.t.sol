// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract TokenFactoryTest is Test {
    BondingCurve bondingCurve;

    function setUp() public {
        bondingCurve = new BondingCurve();
    }

    function test_getFundsNeeded() public {
        uint256 a = 16319324419;
        uint256 b = 1000000000;
        uint256 x0 = 0;
        uint256 deltaX = 800_000_000 ether;

        uint256 factor = 80000000 ether;

        uint256 expectedFundsNeeded = 20 ether;
        uint256 amount;
        for (uint256 i = 1; i <= 10; i++) {
            amount = bondingCurve.getFundsNeeded(a, b, 0, i * factor);
            console.logUint(amount);
        }

        uint256 fundsNeeded = bondingCurve.getFundsNeeded(a, b, x0, deltaX);
        assertGe(
            fundsNeeded,
            expectedFundsNeeded,
            "Funds needed calculation is incorrect"
        );
    }

    function test_GetAmountOut() public {
        uint256 a = 16319324419;
        uint256 b = 1000000000;
        uint256 x0 = 0;
        uint256 deltaY = 20e18;

        uint256 expectedAmountOut = 800000000 ether;

        uint256 amountOut = bondingCurve.getAmountOut(a, b, x0, deltaY);

        assertLe(
            amountOut,
            expectedAmountOut,
            "Amount out calculation is incorrect"
        );
    }
}

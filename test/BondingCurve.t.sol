// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract BondingCurveTest is Test {
    BondingCurve bondingCurve;

    function setUp() public {
        bondingCurve = new BondingCurve(16319324419, 1000000000);
    }

    function test_getFundsReceived() public {
        uint256 x0 = 800_000_000 ether;
        uint256 deltaX = 800_000_000 ether;
        uint256 factor = 40_000_000 ether;

        uint256 fundsReceived_1 = bondingCurve.getFundsReceived(x0, 1);
        console.logUint(fundsReceived_1);

        uint256 expectedFundsNeeded = 20 ether;
        uint256 fundsReceived = bondingCurve.getFundsReceived(x0, deltaX);
        assertGe(
            fundsReceived,
            expectedFundsNeeded,
            "Funds needed calculation is incorrect"
        );
        assertLe(
            fundsReceived,
            expectedFundsNeeded + 0.01 ether,
            "Funds needed calculation is incorrect"
        );
        // buy 1 ETH per step
        uint256 amount = 0;
        uint256 totalAmount = 0;
        for (uint256 i = 20; i >= 1; i--) {
            amount = bondingCurve.getFundsReceived(i * factor, factor);
            totalAmount += amount;
            console.logUint(amount);
        }
        assertLe(
            fundsReceived - totalAmount,
            1000,
            "Total amount calculation is incorrect"
        );
    }

    function test_getAmountOut() public {
        uint256 x0 = 0;
        uint256 deltaY = 20 ether;

        uint256 amountOut_1 = bondingCurve.getAmountOut(x0, 1);
        console.logUint(amountOut_1);

        uint256 expectedAmountOut = 800000000 ether;
        uint256 amountOut = bondingCurve.getAmountOut(x0, deltaY);
        assertLe(
            amountOut,
            expectedAmountOut,
            "Amount out calculation is incorrect"
        );
        assertGe(
            amountOut,
            expectedAmountOut - 1 ether,
            "Amount out calculation is incorrect"
        );

        // buy 1 ETH per step
        uint256 amount = 0;
        uint256 totalAmount = 0;
        for (uint256 i = 1; i <= 20; i++) {
            amount = bondingCurve.getAmountOut(totalAmount, 1 ether);
            totalAmount += amount;
            console.logUint(amount);
        }
        assertLe(
            amountOut - totalAmount,
            0.000001 ether,
            "Total amount calculation is incorrect"
        );
    }

    function test_getInOut() public {
        uint256 x0 = 0;
        uint256 amountOut = bondingCurve.getAmountOut(x0, 1 ether);

        uint256 fundsReceived = bondingCurve.getFundsReceived(
            amountOut,
            amountOut
        );
        assertLe(fundsReceived, 1 ether);
    }
}

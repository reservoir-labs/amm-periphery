// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IReservoirRouter } from "src/interfaces/IReservoirRouter.sol";
import { ReservoirPair } from "amm-core/src/ReservoirPair.sol";

import { ReservoirLibrary } from "src/libraries/ReservoirLibrary.sol";
import { TransferHelper } from "src/libraries/TransferHelper.sol";

import { PeripheryImmutableState } from "src/abstract/PeripheryImmutableState.sol";
import { PeripheryPayments } from "src/abstract/PeripheryPayments.sol";
import { Multicall } from "src/abstract/Multicall.sol";
import { SelfPermit } from "src/abstract/SelfPermit.sol";

contract ReservoirRouter is IReservoirRouter, PeripheryImmutableState, PeripheryPayments, Multicall, SelfPermit {
    constructor(address aFactory, address aWETH) PeripheryImmutableState(aFactory, aWETH) { } // solhint-disable-line no-empty-blocks

    function _addLiquidity(
        address aTokenA,
        address aTokenB,
        uint256 aCurveId,
        uint256 aAmountADesired,
        uint256 aAmountBDesired,
        uint256 aAmountAMin,
        uint256 aAmountBMin
    ) private returns (uint256 rAmountA, uint256 rAmountB, address rPair) {
        rPair = factory.getPair(aTokenA, aTokenB, aCurveId);
        if (rPair == address(0)) {
            rPair = factory.createPair(aTokenA, aTokenB, aCurveId);
        }

        (uint256 lReserveA, uint256 lReserveB) =
            ReservoirLibrary.getReserves(address(factory), aTokenA, aTokenB, aCurveId);
        if (lReserveA == 0 && lReserveB == 0) {
            (rAmountA, rAmountB) = (aAmountADesired, aAmountBDesired);
            return (rAmountA, rAmountB, rPair);
        }
        uint256 lAmountBOptimal = ReservoirLibrary.quote(aAmountADesired, lReserveA, lReserveB);
        if (lAmountBOptimal <= aAmountBDesired) {
            require(lAmountBOptimal >= aAmountBMin, "RR: INSUFFICIENT_B_AMOUNT");
            (rAmountA, rAmountB) = (aAmountADesired, lAmountBOptimal);
        } else {
            uint256 lAmountAOptimal = ReservoirLibrary.quote(aAmountBDesired, lReserveB, lReserveA);
            assert(lAmountAOptimal <= aAmountADesired);
            require(lAmountAOptimal >= aAmountAMin, "RR: INSUFFICIENT_A_AMOUNT");
            (rAmountA, rAmountB) = (lAmountAOptimal, aAmountBDesired);
        }
    }

    function addLiquidity(
        address aTokenA,
        address aTokenB,
        uint256 aCurveId,
        uint256 aAmountADesired,
        uint256 aAmountBDesired,
        uint256 aAmountAMin,
        uint256 aAmountBMin,
        address aTo
    ) external payable returns (uint256 rAmountA, uint256 rAmountB, uint256 rLiq) {
        address lPair;
        (rAmountA, rAmountB, lPair) =
            _addLiquidity(aTokenA, aTokenB, aCurveId, aAmountADesired, aAmountBDesired, aAmountAMin, aAmountBMin);

        _pay(aTokenA, msg.sender, lPair, rAmountA);
        _pay(aTokenB, msg.sender, lPair, rAmountB);

        rLiq = ReservoirPair(lPair).mint(aTo);
    }

    function removeLiquidity(
        address aTokenA,
        address aTokenB,
        uint256 aCurveId,
        uint256 aLiq,
        uint256 aAmountAMin,
        uint256 aAmountBMin,
        address aTo
    ) external payable returns (uint256 rAmountA, uint256 rAmountB) {
        require(aTo != address(0), "RR: TO_ZERO_ADDRESS");
        address lPair = ReservoirLibrary.pairFor(address(factory), aTokenA, aTokenB, aCurveId);
        ReservoirPair(lPair).transferFrom(msg.sender, lPair, aLiq);
        (uint256 lAmount0, uint256 lAmount1) = ReservoirPair(lPair).burn(aTo);

        (address lToken0,) = ReservoirLibrary.sortTokens(aTokenA, aTokenB);
        (rAmountA, rAmountB) = aTokenA == lToken0 ? (lAmount0, lAmount1) : (lAmount1, lAmount0);

        require(rAmountA >= aAmountAMin, "RR: INSUFFICIENT_A_AMOUNT");
        require(rAmountB >= aAmountBMin, "RR: INSUFFICIENT_B_AMOUNT");
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swapExactForVariable(uint256 aAmountIn, address[] memory aPath, uint256[] memory aCurveIds, address aTo)
        private
        returns (uint256 rFinalAmount)
    {
        require(aAmountIn <= type(uint104).max, "RR: AMOUNT_IN_TOO_LARGE");
        int256 lAmount = int256(aAmountIn);
        for (uint256 i = 0; i < aPath.length - 1;) {
            (address lInput, address lOutput) = (aPath[i], aPath[i + 1]);
            (address lToken0,) = ReservoirLibrary.sortTokens(lInput, lOutput);
            address lTo = i < aPath.length - 2
                ? ReservoirLibrary.pairFor(address(factory), lOutput, aPath[i + 2], aCurveIds[i + 1])
                : aTo;
            lAmount = lInput == lToken0 ? int256(lAmount) : -int256(lAmount);

            lAmount = int256(
                ReservoirPair(ReservoirLibrary.pairFor(address(factory), lInput, lOutput, aCurveIds[i])).swap(
                    lAmount, true, lTo, new bytes(0)
                )
            );
            unchecked {
                i += 1;
            }
        }
        // lAmount is guaranteed to be positive at this point
        rFinalAmount = uint256(lAmount);
    }

    function swapExactForVariable(
        uint256 aAmountIn,
        uint256 aAmountOutMin,
        address[] calldata aPath,
        uint256[] calldata aCurveIds,
        address aTo
    ) external payable returns (uint256 rAmountOut) {
        _pay(
            aPath[0],
            msg.sender,
            ReservoirLibrary.pairFor(address(factory), aPath[0], aPath[1], aCurveIds[0]),
            aAmountIn
        );
        rAmountOut = _swapExactForVariable(aAmountIn, aPath, aCurveIds, aTo);
        require(rAmountOut >= aAmountOutMin, "RR: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swapVariableForExact(
        uint256[] memory aAmounts,
        address[] memory aPath,
        uint256[] memory aCurveIds,
        address aTo
    ) private {
        for (uint256 i = 0; i < aPath.length - 1;) {
            (address lInput, address lOutput) = (aPath[i], aPath[i + 1]);
            (address lToken0,) = ReservoirLibrary.sortTokens(lInput, lOutput);
            // PERF: Can avoid branching on every iteration by moving the last step outside of the for loop
            address lTo = i < aPath.length - 2
                ? ReservoirLibrary.pairFor(address(factory), lOutput, aPath[i + 2], aCurveIds[i + 1])
                : aTo;

            int256 lAmount = lOutput == lToken0 ? int256(aAmounts[i + 1]) : -int256(aAmounts[i + 1]);

            ReservoirPair(ReservoirLibrary.pairFor(address(factory), lInput, lOutput, aCurveIds[i])).swap(
                lAmount, false, lTo, new bytes(0)
            );

            unchecked {
                i += 1;
            }
        }
    }

    function swapVariableForExact(
        uint256 aAmountOut,
        uint256 aAmountInMax,
        address[] calldata aPath,
        uint256[] calldata aCurveIds,
        address aTo
    ) external payable returns (uint256[] memory rAmounts) {
        rAmounts = ReservoirLibrary.getAmountsIn(address(factory), aAmountOut, aPath, aCurveIds);
        require(rAmounts[0] <= aAmountInMax, "RR: EXCESSIVE_INPUT_AMOUNT");

        _pay(
            aPath[0],
            msg.sender,
            ReservoirLibrary.pairFor(address(factory), aPath[0], aPath[1], aCurveIds[0]),
            rAmounts[0]
        );
        _swapVariableForExact(rAmounts, aPath, aCurveIds, aTo);
    }
}

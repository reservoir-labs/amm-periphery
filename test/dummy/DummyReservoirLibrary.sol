// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { ReservoirLibrary, ExtraData } from "src/libraries/ReservoirLibrary.sol";

contract DummyReservoirLibrary {
    function getSwapFee(address aFactory, address aTokenA, address aTokenB, uint256 aCurveId)
        external
        view
        returns (uint256)
    {
        return ReservoirLibrary.getSwapFee(aFactory, aTokenA, aTokenB, aCurveId);
    }

    function getPrecisionMultiplier(address aToken) external view returns (uint64) {
        return ReservoirLibrary.getPrecisionMultiplier(aToken);
    }

    function quote(uint256 aAmountA, uint256 aReserveA, uint256 aReserveB) external view returns (uint256) {
        return ReservoirLibrary.quote(aAmountA, aReserveA, aReserveB);
    }

    function getAmountInConstantProduct(uint256 aAmountOut, uint256 aReserveIn, uint256 aReserveOut, uint256 aSwapFee) external view returns (uint256) {
        return ReservoirLibrary.getAmountInConstantProduct(aAmountOut, aReserveIn, aReserveOut, aSwapFee);
    }

    function getAmountInStable(uint256 aAmountOut, uint256 aReserveIn, uint256 aReserveOut, uint256 aSwapFee, ExtraData calldata aExtraData) external view returns (uint256) {
        return ReservoirLibrary.getAmountInStable(aAmountOut, aReserveIn, aReserveOut, aSwapFee, aExtraData);
    }

    function getAmountOutConstantProduct(uint256 aAmountIn, uint256 aReserveIn, uint256 aReserveOut, uint256 aSwapFee) external view returns (uint256) {
        return ReservoirLibrary.getAmountOutConstantProduct(aAmountIn, aReserveIn, aReserveOut, aSwapFee);
    }

    function getAmountOutStable(uint256 aAmountIn, uint256 aReserveIn, uint256 aReserveOut, uint256 aSwapFee, ExtraData calldata aExtraData) external view returns (uint256) {
        return ReservoirLibrary.getAmountOutStable(aAmountIn, aReserveIn, aReserveOut, aSwapFee, aExtraData);
    }
}

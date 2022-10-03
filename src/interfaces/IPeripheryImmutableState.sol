// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import { IGenericFactory } from "v3-core/src/interfaces/IGenericFactory.sol";
import { IWETH } from "src/interfaces/IWETH.sol";

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (IGenericFactory);

    /// @return Returns the address of WETH
    function WETH() external view returns (IWETH);
}

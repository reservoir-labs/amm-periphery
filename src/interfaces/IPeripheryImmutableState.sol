// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import { GenericFactory } from "amm-core/src/GenericFactory.sol";
import { IWETH } from "src/interfaces/IWETH.sol";

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Reservoir generic factory
    function factory() external view returns (GenericFactory);

    /// @return Returns the address of WETH
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (IWETH);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

library TransferHelper {
    error SafeTransferFromFailed();
    error SafeTransferFailed();
    error SafeApproveFailed();
    error SafeTransferETHFailed();

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with SafeTransferFromFailed if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
        // solhint-disable-next-line avoid-low-level-calls
         token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), SafeTransferFromFailed());
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with SafeTransferFailed if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), SafeTransferFailed());
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with SafeApproveFailed if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(address token, address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), SafeApproveFailed());
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with SafeTransferETHFailed
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = to.call{ value: value }(new bytes(0));
        require(success, SafeTransferETHFailed());
    }
}

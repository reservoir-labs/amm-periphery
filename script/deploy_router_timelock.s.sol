// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { ReservoirRouter } from "src/ReservoirRouter.sol";
import { ReservoirTimelock } from "amm-core/src/ReservoirTimelock.sol";

contract DeployRouterTimeLock is Script {
    address internal constant FACTORY = 0x1A49Bc8464731A08c16EdF17F33CF77db37228a4;
    address internal constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function run() external {
        vm.startBroadcast(msg.sender);
        _deployRouter();
        _deployTimelock();
        vm.stopBroadcast();
    }

    function _deployRouter() internal {
        ReservoirRouter lRouter = new ReservoirRouter(FACTORY, WETH);
        require(address(lRouter.FACTORY()) == FACTORY);
        require(address(lRouter.WETH()) == WETH);
    }

    function _deployTimelock() internal {
        ReservoirTimelock lTimelock = new ReservoirTimelock();
        require(lTimelock.delay() == 2 days, "timelock delay mismatch");
    }
}

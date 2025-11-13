// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Quoter } from "src/Quoter.sol";

contract DeployQuoter is Script {
    address internal constant FACTORY = 0x1A49Bc8464731A08c16EdF17F33CF77db37228a4;
    address internal constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function run() external {
        vm.startBroadcast(msg.sender);
        _deployQuoter();
        vm.stopBroadcast();
    }

    function _deployQuoter() internal {
        Quoter lQuoter = new Quoter(FACTORY, WETH);
        require(address(lQuoter.FACTORY()) == FACTORY);
        require(address(lQuoter.WETH()) == WETH);
    }
}

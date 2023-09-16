// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { Quoter } from "src/Quoter.sol";

contract DeployQuoter is Script {
    address internal constant FACTORY = 0xDd723D9273642D82c5761a4467fD5265d94a22da;
    address internal constant WETH_AVAX_MAINNET = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function run() external {
        vm.startBroadcast(msg.sender);
        _deployQuoter();
        vm.stopBroadcast();
    }

    function _deployQuoter() internal {
        Quoter lQuoter = new Quoter(FACTORY, WETH_AVAX_MAINNET);
        require(address(lQuoter.factory()) == FACTORY);
        require(address(lQuoter.WETH()) == WETH_AVAX_MAINNET);
    }
}

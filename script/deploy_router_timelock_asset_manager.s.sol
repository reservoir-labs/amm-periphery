// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { ReservoirRouter } from "src/ReservoirRouter.sol";
import { ReservoirTimelock } from "amm-core/src/ReservoirTimelock.sol";
import { AaveManager, IPoolAddressesProvider } from "amm-core/src/asset-management/AaveManager.sol";

contract DeployRouterTimeLockAaveManager is Script {
    address internal constant FACTORY = 0x47e537e1452DBc9C3eE8F1420e5aaF22111D3547;
    address internal constant WETH_AVAX_MAINNET = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IPoolAddressesProvider internal constant AAVE_POOL_ADDRESSES_PROVIDER = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    function run() external {
        vm.startBroadcast(msg.sender);
        _deployRouter();
        _deployTimelock();
        _deployAaveManager();
        vm.stopBroadcast();
    }

    function _deployRouter() internal {
        new ReservoirRouter(FACTORY, WETH_AVAX_MAINNET);
    }

    function _deployTimelock() internal {
        new ReservoirTimelock();
    }

    function _deployAaveManager() internal {
        new AaveManager(AAVE_POOL_ADDRESSES_PROVIDER);
    }
}

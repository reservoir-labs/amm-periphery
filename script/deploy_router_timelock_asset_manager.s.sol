// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import { ReservoirRouter } from "src/ReservoirRouter.sol";
import { ReservoirTimelock } from "amm-core/src/ReservoirTimelock.sol";
import { AaveManager, IPoolAddressesProvider } from "amm-core/src/asset-management/AaveManager.sol";

contract DeployRouterTimeLockAaveManager is Script {
    address internal constant FACTORY = 0xDd723D9273642D82c5761a4467fD5265d94a22da;
    address internal constant WETH_AVAX_MAINNET = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IPoolAddressesProvider internal constant AAVE_POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    function run() external {
        vm.startBroadcast(msg.sender);
        _deployRouter();
        _deployTimelock();
        _deployAaveManager();
        vm.stopBroadcast();
    }

    function _deployRouter() internal {
        ReservoirRouter lRouter = new ReservoirRouter(FACTORY, WETH_AVAX_MAINNET);
        require(address(lRouter.factory()) == FACTORY);
        require(address(lRouter.WETH()) == WETH_AVAX_MAINNET);
    }

    function _deployTimelock() internal {
        ReservoirTimelock lTimelock = new ReservoirTimelock();
        require(lTimelock.delay() == 2 days);
    }

    function _deployAaveManager() internal {
        AaveManager lManager = new AaveManager(AAVE_POOL_ADDRESSES_PROVIDER);
        require(lManager.addressesProvider() == AAVE_POOL_ADDRESSES_PROVIDER);
    }
}

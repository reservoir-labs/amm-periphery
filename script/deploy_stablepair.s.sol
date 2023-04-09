// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "v3-core/scripts/BaseScript.sol";

import { GenericFactory } from "v3-core/src/GenericFactory.sol";
import { FactoryStoreLib } from "v3-core/src/libraries/FactoryStore.sol";
import { ConstantsLib } from "v3-core/src/libraries/Constants.sol";
import { StablePair } from "v3-core/src/curve/stable/StablePair.sol";
import { StableMintBurn } from "v3-core/src/curve/stable/StableMintBurn.sol";
import { MintableERC20 } from "v3-core/test/__fixtures/MintableERC20.sol";

uint256 constant DEFAULT_SWAP_FEE_SP = 100; // 0.01%
uint256 constant DEFAULT_AMP_COEFF = 1000;

contract DeployStablePair is BaseScript {
    using FactoryStoreLib for GenericFactory;

    // default private key from anvil
    uint256 private _defaultPrivateKey = vm.envUint("TEST_PRIVATE_KEY");
    address private _walletAddress = vm.rememberKey(_defaultPrivateKey);

    GenericFactory private _factory;
    address private _deployedUSDC = 0x5D60473C5Cb323032d6fdFf42380B50E2AE4d245;
    address private _deployedUSDT = 0x6e9FDaE1Fe20b0A5a605C879Ae14030a0aE99cF9;
    address private _router       = 0x7F05c63dC7CA3F99f2d3409f0017C28058C42B27;

    StablePair internal _sp1;

    function _setFactoryAddress() private {
        _factory = GenericFactory(address(_deployer.factory()));
    }

    function _createStablePair() private {
        vm.startBroadcast(_defaultPrivateKey);
        _sp1 = StablePair(_factory.createPair(_deployedUSDC, _deployedUSDT, 1));
        MintableERC20(_deployedUSDC).mint(address(_sp1),   948_192_492_581);
        MintableERC20(_deployedUSDT).mint(address(_sp1), 1_140_591_501_001);
        _sp1.mint(_walletAddress);
        require(_sp1.balanceOf(_walletAddress) > 0, "INSUFFICIENT LIQ");

        _sp1.approve(_router, type(uint256).max);

        // _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 1);
        vm.stopBroadcast();
    }

    function run() external {
        _ensureDeployerExists(_defaultPrivateKey);
        _setFactoryAddress();
        _createStablePair();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "v3-core/scripts/BaseScript.sol";

import { FactoryStoreLib } from "v3-core/src/libraries/FactoryStore.sol";

uint256 constant DEFAULT_SWAP_FEE_SP = 100; // 0.01%
uint256 constant DEFAULT_AMP_COEFF = 1000;

contract SpicyOperations is BaseScript {
    using FactoryStoreLib for GenericFactory;

    bytes private _stableMintBurn = vm.getCode("lib/v3-core/out/StableMintBurn.sol/StableMintBurn.json");
    bytes private _stablePair = vm.getCode("lib/v3-core/out/StablePair.sol/StablePair.json");

    // default private key from anvil
    uint256 private _defaultPrivateKey = 0x9b14b816c3f0bf7bd847bccbd621f9bebbb99b9972998a89e1f3d5af1ec247f6;
    address private _walletAddress;

    function _createStablePair() private {
        vm.startBroadcast(_defaultPrivateKey);
        // add stable curve
        _factory.addBytecode(_stableMintBurn);
        _factory.addCurve(_stablePair);
        _factory.write("SP::swapFee", DEFAULT_SWAP_FEE_SP);
        _factory.write("SP::amplificationCoefficient", DEFAULT_AMP_COEFF);

        _factory.createPair(address(0xD9Bfa7E06B0062d3359D5d8b31596378d9c394B1), address(0x0772281820c550E1C8a890E36B52600dA0407394), 1);
        // _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 1);
        vm.stopBroadcast();
    }

    function run() external {
        _setup(_defaultPrivateKey);
        _createStablePair();
    }
}

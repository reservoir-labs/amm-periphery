// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "v3-core/scripts/BaseScript.sol";
import { ConstantProductPair } from "v3-core/src/curve/constant-product/ConstantProductPair.sol";
import { StableMintBurn } from "v3-core/src/curve/stable/StableMintBurn.sol";
import { StablePair } from "v3-core/src/curve/stable/StablePair.sol";
import { FactoryStoreLib } from "v3-core/src/libraries/FactoryStore.sol";

import { ReservoirRouter } from "src/ReservoirRouter.sol";
import { Quoter } from "src/Quoter.sol";

uint256 constant INITIAL_MINT_AMOUNT = 100e18;
uint256 constant DEFAULT_SWAP_FEE_CP = 3000; // 0.3%
uint256 constant DEFAULT_SWAP_FEE_SP = 100; // 0.01%
uint256 constant DEFAULT_PLATFORM_FEE = 250_000; // 25%
uint256 constant DEFAULT_AMP_COEFF = 1000;
uint256 constant DEFAULT_MAX_CHANGE_RATE = 0.0005e18;

contract SetupScaffold is BaseScript {
    using FactoryStoreLib for GenericFactory;

    address constant public WAVAX_AVAX_MAINNET = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant public USDC_AVAX_MAINNET = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant public USDT_AVAX_MAINNET = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;

    ReservoirRouter private _router;
    Quoter private _quoter;

    function _deployPeriphery() private {
        _router = new ReservoirRouter(address(_factory), WAVAX_AVAX_MAINNET);
        _quoter = new Quoter(address(_factory), WAVAX_AVAX_MAINNET);
    }

    function _deployCore() private {
        _setup();

        vm.startBroadcast();
        // set shared variables
        _factory.write("Shared::platformFee", DEFAULT_PLATFORM_FEE);
        // _factory.write("Shared::platformFeeTo", _platformFeeTo);
        // _factory.write("Shared::defaultRecoverer", _recoverer);
        _factory.write("Shared::maxChangeRate", DEFAULT_MAX_CHANGE_RATE);

        // add constant product curve
        _factory.addCurve(type(ConstantProductPair).creationCode);
        _factory.write("CP::swapFee", DEFAULT_SWAP_FEE_CP);

        // add stable curve
        _factory.addBytecode(type(StableMintBurn).creationCode);
        _factory.addCurve(type(StablePair).creationCode);
        _factory.write("SP::swapFee", DEFAULT_SWAP_FEE_SP);
        _factory.write("SP::amplificationCoefficient", DEFAULT_AMP_COEFF);

        _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 0);
        _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 1);
        _factory.createPair(USDC_AVAX_MAINNET, USDT_AVAX_MAINNET, 1);
        vm.stopBroadcast();

        address[] memory lAllPairs = _factory.allPairs();
        require(lAllPairs.length == 3, "Wrong number of pairs created");
    }

    function run() external {
        _deployCore();
        _deployPeriphery();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { WETH } from "solmate/tokens/WETH.sol";

import "v3-core/scripts/BaseScript.sol";
import { ConstantProductPair } from "v3-core/src/curve/constant-product/ConstantProductPair.sol";
import { StableMintBurn } from "v3-core/src/curve/stable/StableMintBurn.sol";
import { StablePair } from "v3-core/src/curve/stable/StablePair.sol";
import { FactoryStoreLib } from "v3-core/src/libraries/FactoryStore.sol";
import { MintableERC20 } from "v3-core/test/__fixtures/MintableERC20.sol";

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

    MintableERC20 internal _usdc;
    MintableERC20 internal _usdt;
    WETH internal _wavax;

    // default private key from anvil
    uint256 private _defaultPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address private _walletAddress;

    function _deployInfra() private {
        vm.startBroadcast(_defaultPrivateKey);
        _usdc = new MintableERC20("USD Circle", "USDC", 6);
        _usdt = new MintableERC20("USD Tether", "USDT", 6);
        _wavax = new WETH();
        _wavax.deposit{value: 5_000 ether}();
        require(_wavax.balanceOf(_walletAddress) == 5_000 ether, "WAVAX AMT WRONG");
        vm.stopBroadcast();
    }

    function _deployCore() private {
        _setup(_defaultPrivateKey);

        vm.startBroadcast(_defaultPrivateKey);
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

        ConstantProductPair lPair1 = ConstantProductPair(_factory.createPair(address(_usdt), address(_usdc), 0));
        _usdc.mint(address(lPair1), 1_000_000e6);
        _usdt.mint(address(lPair1), 950_000e6);
        lPair1.mint(address(this));
        require(lPair1.balanceOf(address(this)) > 0, "INSUFFICIENT LIQ");
        // _factory.createPair(USDC_AVAX_MAINNET, USDT_AVAX_MAINNET, 1);
        // _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 1);
        vm.stopBroadcast();

        address[] memory lAllPairs = _factory.allPairs();
        require(lAllPairs.length == 1, "Wrong number of pairs created");
    }

    function _deployPeriphery() private {
        vm.startBroadcast(_defaultPrivateKey);
        _router = new ReservoirRouter(address(_factory), WAVAX_AVAX_MAINNET);
        _quoter = new Quoter(address(_factory), WAVAX_AVAX_MAINNET);
        vm.stopBroadcast();
    }

    function run() external {
        _walletAddress = vm.rememberKey(_defaultPrivateKey);
        _deployInfra();
        _deployCore();
        _deployPeriphery();
    }
}

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

    // Bytecode (we want to ensure we grab the exact one, not whatever forge script produces).
    bytes private _constantProductPair = vm.getCode("lib/v3-core/out/ConstantProductPair.sol/ConstantProductPair.json");
    bytes private _stableMintBurn = vm.getCode("lib/v3-core/out/StableMintBurn.sol/StableMintBurn.json");
    bytes private _stablePair = vm.getCode("lib/v3-core/out/StablePair.sol/StablePair.json");

    function _deployInfra() private {
        vm.startBroadcast(_defaultPrivateKey);
        _usdc = new MintableERC20("USD Circle", "USDC", 6);
        _usdt = new MintableERC20("USD Tether", "USDT", 6);
        _wavax = new WETH();
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
        _factory.addCurve(_constantProductPair);
        _factory.write("CP::swapFee", DEFAULT_SWAP_FEE_CP);

        // add stable curve
        _factory.addBytecode(_stableMintBurn);
        _factory.addCurve(_stablePair);
        _factory.write("SP::swapFee", DEFAULT_SWAP_FEE_SP);
        _factory.write("SP::amplificationCoefficient", DEFAULT_AMP_COEFF);

        ConstantProductPair lPair1 = ConstantProductPair(_factory.createPair(address(_usdt), address(_usdc), 0));
        _usdc.mint(address(lPair1), 1_000_000e6);
        _usdt.mint(address(lPair1), 950_000e6);
        lPair1.mint(address(this));
        require(lPair1.balanceOf(address(this)) > 0, "INSUFFICIENT LIQ");
        _factory.createPair(address(_usdc), address(_usdt), 1);
//        _factory.createPair(WAVAX_AVAX_MAINNET, USDC_AVAX_MAINNET, 1);
        vm.stopBroadcast();

        address[] memory lAllPairs = _factory.allPairs();
        // require(lAllPairs.length == 1, "Wrong number of pairs created");
    }

    function _deployPeriphery() private {

        _router = ReservoirRouter(
            payable(
                Create2Lib.computeAddress(
                    CREATE2_FACTORY,
                    abi.encodePacked(type(ReservoirRouter).creationCode, abi.encode(address(_factory), address(_wavax))),
                    bytes32(uint256(0))
                )
            )
        );
        if (address(_router).code.length == 0) {
            vm.broadcast(_defaultPrivateKey);
            ReservoirRouter lRouter = new ReservoirRouter{salt: bytes32(uint256(0))}(address(_factory), address(_wavax));

            require(lRouter == _router, "Create2 Address Mismatch for ReservoirRouter");
        }

        _quoter = Quoter(
            Create2Lib.computeAddress(
                CREATE2_FACTORY,
                abi.encodePacked(type(Quoter).creationCode, abi.encode(address(_factory), address(_wavax))),
                bytes32(uint256(0))
            )
        );
        if (address(_quoter).code.length == 0) {
            vm.broadcast(_defaultPrivateKey);
            Quoter lQuoter = new Quoter{salt: bytes32(uint256(0))}(address(_factory), address(_wavax));

            require(lQuoter == _quoter, "Create2 Address mismatch for Quoter");
        }
    }

    function _getRichAndApproveRouter() private {
        vm.startBroadcast(_defaultPrivateKey);
        _usdc.mint(_walletAddress, 1_000_000e6);
        _usdt.mint(_walletAddress, 1_000_000e6);
        _wavax.deposit{value: 5_000 ether}();
        require(_wavax.balanceOf(_walletAddress) == 5_000 ether, "WAVAX AMT WRONG");
        _usdc.approve(address(_router), type(uint256).max);
        _usdt.approve(address(_router), type(uint256).max);
        vm.stopBroadcast();
    }

    function run() external {
        _walletAddress = vm.rememberKey(_defaultPrivateKey);
        _deployInfra();
        _deployCore();
        _deployPeriphery();
        _getRichAndApproveRouter();
    }
}

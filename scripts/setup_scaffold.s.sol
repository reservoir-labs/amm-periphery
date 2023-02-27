// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { WETH } from "solmate/tokens/WETH.sol";

import "v3-core/scripts/BaseScript.sol";
import { ConstantProductPair } from "v3-core/src/curve/constant-product/ConstantProductPair.sol";
import { FactoryStoreLib } from "v3-core/src/libraries/FactoryStore.sol";
import { MintableERC20 } from "v3-core/test/__fixtures/MintableERC20.sol";

import { ReservoirRouter } from "src/ReservoirRouter.sol";
import { Quoter } from "src/Quoter.sol";

uint256 constant INITIAL_MINT_AMOUNT = 100e18;
uint256 constant DEFAULT_SWAP_FEE_CP = 3000; // 0.3%
uint256 constant DEFAULT_PLATFORM_FEE = 250_000; // 25%
uint256 constant DEFAULT_MAX_CHANGE_RATE = 0.0005e18;

contract SetupScaffold is BaseScript {
    using FactoryStoreLib for GenericFactory;

    ReservoirRouter private _router;
    Quoter private _quoter;

    MintableERC20 internal _usdc;
    MintableERC20 internal _usdt;
    WETH internal _wavax;
    ConstantProductPair internal _cp1;
    ConstantProductPair internal _cp2;

    // default private key from anvil
    uint256 private _defaultPrivateKey = vm.envUint("PRIVATE_KEY");
    address private _walletAddress;

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
        _factory.addCurve(type(ConstantProductPair).creationCode);
        _factory.write("CP::swapFee", DEFAULT_SWAP_FEE_CP);

        vm.stopBroadcast();
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

    function _getRich() private {
        uint256 lAmtToWrap = 1 ether;
        vm.startBroadcast(_defaultPrivateKey);
        _usdc.mint(_walletAddress, 1_000_000e6);
        _usdt.mint(_walletAddress, 1_000_000e6);
        _wavax.deposit{value: lAmtToWrap}();
        require(_wavax.balanceOf(_walletAddress) == lAmtToWrap, "WAVAX AMT WRONG");
        vm.stopBroadcast();
    }

    function _deployPairs() private {
        vm.startBroadcast(_defaultPrivateKey);
        _cp1 = ConstantProductPair(_factory.createPair(address(_usdt), address(_usdc), 0));
        _usdc.mint(address(_cp1), 1_000_000e6);
        _usdt.mint(address(_cp1), 950_000e6);
        _cp1.mint(_walletAddress);

        _cp2 = ConstantProductPair(_factory.createPair(address(_wavax), address(_usdc), 0));
        _usdc.mint(address(_cp2), 103_392_049_192);
        _wavax.transfer(address(_cp2), 302_291_291_321_201_392);
        _cp2.mint(_walletAddress);

        require(_cp1.balanceOf(_walletAddress) > 0, "INSUFFICIENT LIQ");
        require(_cp2.balanceOf(_walletAddress) > 0, "INSUFFICIENT LIQ");
        vm.stopBroadcast();
    }

    function _approveRouter() private {
        vm.startBroadcast(_defaultPrivateKey);
        _usdc.approve(address(_router), type(uint256).max);
        _usdt.approve(address(_router), type(uint256).max);
        _wavax.approve(address(_router), type(uint256).max);
        _cp1.approve(address(_router), type(uint256).max);
        _cp2.approve(address(_router), type(uint256).max);
        vm.stopBroadcast();
    }

    function run() external {
        _walletAddress = vm.rememberKey(_defaultPrivateKey);
        _deployInfra();
        _deployCore();
        _deployPeriphery();
        _getRich();
        _deployPairs();
        _approveRouter();
    }
}

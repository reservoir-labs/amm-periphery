pragma solidity 0.8.13;

import "v3-core/test/__fixtures/BaseTest.sol";

import { WETH } from "solmate/tokens/WETH.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

import { MathUtils } from "v3-core/src/libraries/MathUtils.sol";

import { IReservoirPair } from "v3-core/src/interfaces/IReservoirPair.sol";
import { ExtraData } from "src/interfaces/IReservoirRouter.sol";
import { ReservoirLibrary, IGenericFactory } from "src/libraries/ReservoirLibrary.sol";
import { ReservoirRouter } from "src/ReservoirRouter.sol";

contract ReservoirRouterTest is BaseTest
{
    WETH            private _weth   = new WETH();
    ReservoirRouter private _router = new ReservoirRouter(address(_factory), address(_weth));

    bytes[]         private _data;

    function testAddLiquidity(uint256 aTokenAMintAmt, uint256 aTokenBMintAmt) public
    {
        // arrange
        uint256 lTokenAMintAmt = bound(aTokenAMintAmt, 1, type(uint112).max);
        uint256 lTokenBMintAmt = bound(aTokenBMintAmt, 1, type(uint112).max);
        _tokenA.mint(_bob, lTokenAMintAmt);
        _tokenB.mint(_bob, lTokenBMintAmt);

        vm.startPrank(_bob);
        _tokenA.approve(address(_router), type(uint256).max);
        _tokenB.approve(address(_router), type(uint256).max);

        // act
        _data.push(abi.encodeCall(
            _router.addLiquidity,
            (
                address(_tokenA),
                address(_tokenB),
                0,
                lTokenAMintAmt,
                lTokenBMintAmt,
                1,
                1,
                _bob
            )
        ));

        bytes[] memory lResult = _router.multicall(_data);

        // assert
        ReservoirPair lPair = ReservoirPair(
                                ReservoirLibrary.pairFor(
                                    address(_factory),
                                    address(_tokenA),
                                    address(_tokenB),
                                    0
                                ));
        (uint256 lAmountA, uint256 lAmountB, uint256 lLiquidity) = abi.decode(lResult[0], (uint256, uint256, uint256));
        assertEq(lLiquidity, FixedPointMathLib.sqrt(lAmountA * lAmountB));
        assertEq(lPair.balanceOf(_bob), lLiquidity);
        assertEq(_tokenA.balanceOf(_bob), lTokenAMintAmt - lAmountA);
        assertEq(_tokenB.balanceOf(_bob), lTokenBMintAmt - lAmountB);
        assertEq(_tokenA.balanceOf(address(lPair)), INITIAL_MINT_AMOUNT + lAmountA);
        assertEq(_tokenB.balanceOf(address(lPair)), INITIAL_MINT_AMOUNT + lAmountB);
    }

    function testAddLiquidity_CreatePair_CP() public
    {
        // arrange
        uint256 lTokenAMintAmt = 5000e18;
        uint256 lTokenCMintAmt = 1000e18;
        _tokenA.mint(_bob, lTokenAMintAmt);
        _tokenC.mint(_bob, lTokenCMintAmt);
        vm.startPrank(_bob);
        _tokenA.approve(address(_router), type(uint256).max);
        _tokenC.approve(address(_router), type(uint256).max);

        // sanity
        assertEq(_tokenA.allowance(_bob, address(_router)), type(uint256).max);
        assertEq(_tokenC.allowance(_bob, address(_router)), type(uint256).max);

        // act
        (uint256 lAmountA, uint256 lAmountB, uint256 lLiquidity)
            = _router.addLiquidity(address(_tokenA), address(_tokenC), 0, lTokenAMintAmt, lTokenCMintAmt, 500e18, 500e18, _bob);

        // assert
        ReservoirPair lPair = ReservoirPair(_factory.getPair(address(_tokenC), address(_tokenA), 0));
        assertEq(lLiquidity, FixedPointMathLib.sqrt(lTokenAMintAmt * lTokenCMintAmt) - lPair.MINIMUM_LIQUIDITY());
        assertEq(lPair.balanceOf(_bob), lLiquidity);
        assertEq(_tokenA.balanceOf(_bob), 0);
        assertEq(_tokenC.balanceOf(_bob), 0);
        assertEq(_tokenA.balanceOf(address(lPair)), lTokenAMintAmt);
        assertEq(_tokenC.balanceOf(address(lPair)), lTokenCMintAmt);
    }

    function testAddLiquidity_CreatePair_ConstantProduct_Native() public
    {
        // arrange
        uint256 lTokenAMintAmt = 5000e18;
        uint256 lEthMintAmt = 5 ether;
        _tokenA.mint(_bob, lTokenAMintAmt);
        deal(_bob, 10 ether);
        vm.startPrank(_bob);
        _tokenA.approve(address(_router), type(uint256).max);

        // act
        _data.push(abi.encodeCall(
            _router.addLiquidity,
            (
                address(_weth),
                address(_tokenA),
                0,
                5 ether,
                lTokenAMintAmt,
                1e18,
                1e18,
                _bob
            )
        ));
        _data.push(abi.encodeCall(
            _router.refundETH,
            ()
        ));

        bytes[] memory lResult = _router.multicall{value: 5 ether}(_data);

        // assert
        ReservoirPair lPair = ReservoirPair(_factory.getPair(address(_weth), address(_tokenA), 0));
        (uint256 lAmountA, uint256 lAmountB, uint256 lLiquidity) = abi.decode(lResult[0], (uint256, uint256, uint256));
        assertEq(lLiquidity, FixedPointMathLib.sqrt(lTokenAMintAmt * lEthMintAmt) - lPair.MINIMUM_LIQUIDITY());
        assertEq(lPair.balanceOf(_bob), lLiquidity);
        assertEq(_tokenA.balanceOf(_bob), 0);
        assertEq(_weth.balanceOf(_bob), 0);
        assertEq(_bob.balance, 5 ether);
        assertEq(_tokenA.balanceOf(address(lPair)), lTokenAMintAmt);
        assertEq(_weth.balanceOf(address(lPair)), lEthMintAmt);
    }

    function testAddLiquidity_ConstantProduct_Native_RefundETH() public
    {

    }

    function testRemoveLiquidity(uint256 aAmountToRemove) public
    {
        // arrange
        uint256 lStartingBalance = _constantProductPair.balanceOf(_alice);
        uint256 lAmountToRemove = bound(aAmountToRemove, 1, lStartingBalance);
        vm.startPrank(_alice);
        _constantProductPair.approve(address(_router), lAmountToRemove);

        // act
        _data.push(abi.encodeCall(
            _router.removeLiquidity,
            (
                address(_tokenA),
                address(_tokenB),
                0,
                lAmountToRemove,
                1,
                1,
                address(_alice)
            )
        ));

        bytes[] memory lResult = _router.multicall(_data);

        // assert
        (uint256 lAmountA, uint256 lAmountB) = abi.decode(lResult[0], (uint256, uint256));
        assertEq(_constantProductPair.balanceOf(_alice), lStartingBalance - lAmountToRemove);
        assertEq(_tokenA.balanceOf(_alice), lAmountA);
        assertEq(_tokenB.balanceOf(_alice), lAmountB);
    }

    function testRemoveLiquidity_Native() public
    {
        // arrange
        testAddLiquidity_CreatePair_ConstantProduct_Native();
        // clear data from previous test
        delete _data;
        ReservoirPair lPair = ReservoirPair(ReservoirLibrary.pairFor(address(_factory), address(_tokenA), address(_weth), 0));
        uint256 lLiq = lPair.balanceOf(_bob);
        lPair.approve(address(_router), lLiq);

        // act
        _data.push(abi.encodeCall(
            _router.removeLiquidity,
            (
                address(_tokenA),
                address(_weth),
                0,
                lLiq,
                1,
                1,
                address(_router)
            )
        ));
        _data.push(abi.encodeCall(
            _router.sweepToken,
            (
                address(_tokenA),
                500, // whatever
                _bob
            )
        ));
        _data.push(abi.encodeCall(
            _router.unwrapWETH,
            (
                5, // wtv
                _bob
            )
        ));

        bytes[] memory lResult = _router.multicall(_data);

        // assert
        assertEq(lPair.balanceOf(_bob), 0);
        assertEq(_tokenA.balanceOf(_bob), lLiq * 5000e18 / (lLiq + lPair.MINIMUM_LIQUIDITY()));
        assertEq(_bob.balance,  5 ether + lLiq * 5 ether / (lLiq + lPair.MINIMUM_LIQUIDITY()));
    }

    function testQuoteAddLiquidity(uint256 aAmountAToAdd, uint256 aAmountBToAdd) public
    {
        // arrange
        uint256 lAmountAToAdd = bound(aAmountAToAdd, 1000, type(uint112).max);
        uint256 lAmountBToAdd = bound(aAmountBToAdd, 1000, type(uint112).max);

        // act
        (uint256 lAmountAOptimal, uint256 lAmountBOptimal, uint256 lLiq)
            = _router.quoteAddLiquidity(address(_tokenA), address(_tokenB), 0, lAmountAToAdd, lAmountBToAdd);

        // assert
        assertEq(lAmountAOptimal, Math.min(lAmountAToAdd, lAmountBToAdd));
        assertEq(lAmountBOptimal, lAmountAOptimal);

        assertEq(lLiq, FixedPointMathLib.sqrt(lAmountAOptimal * lAmountBOptimal));
    }

    function testQuoteAddLiquidity_Stable(uint256 aAmountAToAdd, uint256 aAmountBToAdd) public
    {
        // arrange
        uint256 lAmountAToAdd = bound(aAmountAToAdd, 1000, type(uint112).max);
        uint256 lAmountBToAdd = bound(aAmountBToAdd, 1000, type(uint112).max);

        // act
        (uint256 lAmountAOptimal, uint256 lAmountBOptimal, uint256 lLiq)
            = _router.quoteAddLiquidity(address(_tokenA), address(_tokenB), 1, lAmountAToAdd, lAmountBToAdd);

        // assert
        assertEq(lAmountAOptimal, Math.min(lAmountAToAdd, lAmountBToAdd));
        assertEq(lAmountBOptimal, lAmountAOptimal);
        assertEq(lLiq, lAmountAOptimal + lAmountBOptimal);
    }

    function testQuoteRemoveLiquidity(uint256 aLiquidity) public
    {
        // arrange
        uint256 lLiquidity = bound(aLiquidity, 1, _constantProductPair.balanceOf(_alice));

        // act
        (uint256 lAmountA, uint256 lAmountB) = _router.quoteRemoveLiquidity(address(_tokenA), address(_tokenB), 0, lLiquidity);
        testRemoveLiquidity(lLiquidity);

        // assert
        assertTrue(MathUtils.within1(lAmountA, _tokenA.balanceOf(_alice)));
    }

    function testCheckDeadline(uint256 aDeadline) public
    {
        // arrange
        uint256 lDeadline = bound(aDeadline, 1, type(uint64).max);
        uint256 lTimeToJump = bound(aDeadline, 0, lDeadline - 1);
        _stepTime(lTimeToJump);
        _data.push(abi.encodeCall(_router.checkDeadline, (lDeadline)));

        // act
        _router.multicall(_data);
    }

    function testCheckDeadline_PastDeadline(uint256 aDeadline) public
    {
        // arrange
        uint256 lTimeToJump = bound(aDeadline, 1, type(uint64).max);
        uint256 lDeadline = bound(aDeadline, 1, lTimeToJump);
        _stepTime(lTimeToJump);
        _data.push(abi.encodeCall(_router.checkDeadline, (lDeadline)));

        // act & assert
        vm.expectRevert("PH: TX_TOO_OLD");
        _router.multicall(_data);
    }

    function testGetAmountOut_ErrorChecking(uint256 aCurveId, uint256 aAmountIn) public
    {
        // arrange - might not be the best solution, but it prevents repeated code
        aCurveId = bound(aCurveId, 0, 1);
        uint256 lAmountIn = bound(aAmountIn, 1, type(uint112).max);

        // act & revert
        vm.expectRevert("RL: INSUFFICIENT_INPUT_AMOUNT");
        _router.getAmountOut(0, 10, 10, aCurveId, 30, ExtraData(0,0,0));

        vm.expectRevert("RL: INSUFFICIENT_LIQUIDITY");
        _router.getAmountOut(lAmountIn, 0, 0, aCurveId, 0, ExtraData(0,0,0));
    }

    function testGetAmountOut_CP(uint256 aAmountIn) public
    {
        // arrange
        (uint112 lReserve0, uint112 lReserve1, ) = _constantProductPair.getReserves();
        uint256 lAmountIn = bound(aAmountIn, 1, type(uint112).max);
        _tokenA.mint(address(_constantProductPair), lAmountIn);
        uint256 lSwapFee = _constantProductPair.swapFee();

        // act
        uint256 lAmountOut = _router.getAmountOut(lAmountIn, lReserve0, lReserve1, 0, lSwapFee, ExtraData(0,0,0));
        uint256 lActualAmountOut = _constantProductPair.swap(int256(lAmountIn), true, address(this), bytes(""));

        // assert
        assertLt(lAmountOut, lAmountIn);
        assertEq(lAmountOut, lActualAmountOut);
    }

    function testGetAmountOut_SP(uint256 aAmountIn) public
    {
        // arrange
        (uint112 lReserve0, uint112 lReserve1, ) = _stablePair.getReserves();
        uint256 lAmountIn = bound(aAmountIn, 1, type(uint112).max);
        _tokenA.mint(address(_stablePair), lAmountIn);
        uint256 lSwapFee = _stablePair.swapFee();
        uint64 lToken0PrecisionMultiplier = ReservoirLibrary.getPrecisionMultiplier(_stablePair.token0());
        uint64 lToken1PrecisionMultiplier = ReservoirLibrary.getPrecisionMultiplier(_stablePair.token1());
        uint64 lA = ReservoirLibrary.getAmplificationCoefficient(address(_stablePair));

        // act
        uint256 lAmountOut
            = _router.getAmountOut(
                lAmountIn,
                lReserve0,
                lReserve1,
                1,
                lSwapFee,
                ExtraData(lToken0PrecisionMultiplier,lToken1PrecisionMultiplier, lA)
        );
        uint256 lActualAmountOut = _stablePair.swap(int256(lAmountIn), true, address(this), bytes(""));

        // assert
        assertLt(lAmountOut, lAmountIn);
        assertEq(lAmountOut, lActualAmountOut);
    }

    function testGetAmountIn_ErrorChecking(uint256 aCurveId, uint256 aAmountOut) public
    {
        // arrange
        aCurveId = bound(aCurveId, 0, 1);
        uint256 aAmountOut = bound(aAmountOut, 1, type(uint112).max);

        // act & revert
        vm.expectRevert("RL: INSUFFICIENT_OUTPUT_AMOUNT");
        _router.getAmountIn(0, 10, 10, aCurveId, 30, ExtraData(0,0,0));

        vm.expectRevert("RL: INSUFFICIENT_LIQUIDITY");
        _router.getAmountIn(aAmountOut, 0, 0, aCurveId, 0, ExtraData(0,0,0));
    }

    function testGetAmountIn_CP(uint256 aAmountOut) public
    {
        // arrange
        (uint112 lReserve0, uint112 lReserve1, ) = _constantProductPair.getReserves();
        uint256 lAmountOut = bound(aAmountOut, 1000, lReserve1 / 2);
        uint256 lSwapFee = _constantProductPair.swapFee();

        // act
        uint256 lAmountIn = _router.getAmountIn(lAmountOut, lReserve0, lReserve1, 0, lSwapFee, ExtraData(0,0,0));
        _tokenA.mint(address(_constantProductPair), lAmountIn);
        uint256 lActualAmountOut = _constantProductPair.swap(-int256(lAmountOut), false, address(this), bytes(""));

        // assert
        assertLt(lAmountOut, lAmountIn);
        assertEq(lAmountOut, lActualAmountOut);
    }

    function testGetAmountIn_SP(uint256 aAmountOut) public
    {
        // arrange
        (uint112 lReserve0, uint112 lReserve1, ) = _stablePair.getReserves();
        uint256 lAmountOut = bound(aAmountOut, 1, lReserve1 / 2);
        uint256 lSwapFee = _stablePair.swapFee();
        uint64 lToken0PrecisionMultiplier = ReservoirLibrary.getPrecisionMultiplier(_stablePair.token0());
        uint64 lToken1PrecisionMultiplier = ReservoirLibrary.getPrecisionMultiplier(_stablePair.token1());
        uint64 lA = ReservoirLibrary.getAmplificationCoefficient(address(_stablePair));

        // act
        uint256 lAmountIn
            = _router.getAmountIn(
                lAmountOut,
                lReserve0,
                lReserve1,
                1,
                lSwapFee,
                ExtraData(lToken0PrecisionMultiplier,lToken1PrecisionMultiplier, lA)
        );
        _tokenA.mint(address(_stablePair), lAmountIn);
        uint256 lActualAmountOut = _stablePair.swap(-int256(lAmountOut), false, address(this), bytes(""));

        // assert
        assertLt(lAmountOut, lAmountIn);
        assertEq(lAmountOut, lActualAmountOut);
    }
}

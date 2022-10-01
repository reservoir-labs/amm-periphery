pragma solidity 0.8.13;

struct ExtraData {
    uint64 token0PrecisionMultiplier;
    uint64 token1PrecisionMultiplier;
    uint64 amplificationCoefficient;
}

interface IReservoirRouter {

    /*//////////////////////////////////////////////////////////////////////////
                                LIQUIDITY METHODS
    //////////////////////////////////////////////////////////////////////////*/

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 curveId,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external payable returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 curveId,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB);

    /*//////////////////////////////////////////////////////////////////////////
                                SWAP METHODS
    //////////////////////////////////////////////////////////////////////////*/

    function swapExactForVariable(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256[] calldata curveIds,
        address to
    ) external payable returns (uint256[] memory amounts);

    function swapVariableForExact(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256[] calldata curveIds,
        address to
    ) external payable returns (uint256[] memory amounts);

    /*//////////////////////////////////////////////////////////////////////////
                                QUERY METHODS (VIEW)
    //////////////////////////////////////////////////////////////////////////*/

    /// @param extraData for StablePair use, to leave blank for ConstantProductPair. See ReservoirLibrary
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 curveId,
        uint256 swapFee,
        ExtraData calldata extraData
    ) external pure returns(uint256 amountOut);

    /// @param extraData for StablePair use, to leave blank for ConstantProductPair. See ReservoirLibrary
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 curveId,
        uint256 swapFee,
        ExtraData calldata extraData
    ) external pure returns(uint256 amountIn);

    /// @param path array of ERC20 tokens to swap into
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path,
        uint256[] calldata curveIds
    ) external view returns(uint256[] memory amountsOut);

    /// @param path array of ERC20 tokens to swap into
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path,
        uint256[] calldata curveIds
    ) external view returns(uint256[] memory amountsIn);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        uint256 curveId,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        uint256 curveId,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);
}

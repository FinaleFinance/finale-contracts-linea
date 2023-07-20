// interfaces/Interfaces.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IPool {
    struct TokenAmount {
        address token;
        uint amount;
    }
}

interface ISyncRouter {
    struct SwapStep {
        address pool;
        bytes data;
        address callback;
        bytes callbackData;
    }

    struct SwapPath {
        SwapStep[] steps;
        address tokenIn;
        uint amountIn;
    }

    function swap(
        SwapPath[] memory paths,
        uint amountOutMin,
        uint deadline
    ) external payable returns (IPool.TokenAmount memory amountOut);
}

interface IHorizonRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    function swapExactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IEchoRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Params {
    struct SwapParam {
        address poolAddress;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOutMin;
        uint swapType;
        uint24 fee;
    }
}

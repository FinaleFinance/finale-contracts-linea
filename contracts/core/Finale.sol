// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ReentrancyGuard.sol";
import "../interfaces/Interfaces.sol";
import "./ContractErrors.sol";
import "../utils/Ownable.sol";
import "../utils/Math.sol";

/**
 * @title Finale Contract
 * @dev The Finale contract allows users to perform token swaps using the ISyncRouter, IHorizonRouter and IEchoRouter interfaces.
 * It provides functions for approving tokens, executing swaps, and handling token transfers.
 * The contract also includes reentrancy guard, contract error handling, and ownership functionality.
 */
contract Finale is ReentrancyGuard, ContractErrors, Ownable {
    using Math for uint;
    event SwapExecuted(
        address indexed user, 
        address tokenIn, 
        address tokenOut, 
        uint amountIn, 
        uint amountOut, 
        uint swapType
    );
    event PathsExecuted(
        address indexed user,
        Params.SwapParam[] swapParams,
        uint minTotalAmountOut,
        uint finalTokenAmount
    );

    ISyncRouter syncRouter;
    address public _syncrouterAddress = 0xB3b7fCbb8Db37bC6f572634299A58f51622A847e;
    IHorizonRouter horizonRouter;
    address public _horizonrouterAddress = 0x272E156Df8DA513C69cB41cC7A99185D53F926Bb;
    IEchoRouter echoRouter;
    address public _echoRouterAddress = 0xc66149996d0263C0B42D3bC05e50Db88658106cE;
    address public _fee_address = 0xCA11332523f17A524b71990AEc94113f8ABe07cB;

    constructor() ReentrancyGuard() Ownable(msg.sender) {
        syncRouter = ISyncRouter(_syncrouterAddress);
        horizonRouter = IHorizonRouter(_horizonrouterAddress);
        echoRouter = IEchoRouter(_echoRouterAddress);
    }

    /**
     * @notice Sets the maximum allowances for the specified tokens to the syncRouter,horizonrouter and echorouter addresses.
     * @dev Only the contract owner can call this function.
     * @param tokens Array of token addresses.
     */
    function maxApprovals(address[] calldata tokens) external onlyOwner {
        for(uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if(!token.approve(_horizonrouterAddress, type(uint256).max)) revert ApprovalFailedError(tokens[i], _horizonrouterAddress);
            if(!token.approve(_echoRouterAddress, type(uint256).max)) revert ApprovalFailedError(tokens[i], _echoRouterAddress);
        }
    }

    /**
     * @notice Revokes the allowances for the specified tokens from the syncRouter,horizonrouter and echorouter addresses.
     * @dev Only the contract owner can call this function.
     * @param tokens Array of token addresses.
     */
    function revokeApprovals(address[] calldata tokens) external onlyOwner {
        for(uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if(!token.approve(_horizonrouterAddress, 0)) revert RevokeApprovalFailedError(tokens[i], _horizonrouterAddress);
            if(!token.approve(_echoRouterAddress, 0)) revert RevokeApprovalFailedError(tokens[i], _echoRouterAddress);
        }
    }

    /**
     * @notice Executes a token swap on HorizonDex.
     * @dev This function is internal, meaning it can only be called by this contract.
     * @param tokenIn The address of the input token for the swap.
     * @param tokenOut The address of the output token for the swap.
     * @param fee The fee for the swap.
     * @param amountIn The amount of input tokens to be swapped.
     * @return A struct containing the address of the output token and the amount of output tokens received.
     */
    function horizonDex(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint amountIn
    ) internal returns (IPool.TokenAmount memory) {
        IHorizonRouter.ExactInputSingleParams memory params = IHorizonRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 20 minutes,
            amountIn: amountIn,
            minAmountOut: 0,
            limitSqrtP: 0  
        });

        uint amounts = horizonRouter.swapExactInputSingle(params);

        IPool.TokenAmount memory tokenOutAmount;
        tokenOutAmount.token = tokenOut;
        tokenOutAmount.amount = amounts;
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amounts, 2);
        return tokenOutAmount;
    }
    /**
     * @notice Executes a token swap on a specific pool using SyncSwap.
     * @dev This function is internal, meaning it can only be called by this contract.
     * @param poolAddress The address of the pool on which the swap should be executed.
     * @param tokenIn The address of the input token for the swap.
     * @param amountIn The amount of input tokens to be swapped.
     * @return A struct containing the address of the output token and the amount of output tokens received.
     */
    function syncswap(
        address poolAddress,
        address tokenIn,
        uint amountIn
    ) internal returns (IPool.TokenAmount memory) {
        bytes memory swapData = abi.encode(tokenIn, address(this), uint8(2));
        ISyncRouter.SwapStep memory step = ISyncRouter.SwapStep({
            pool: poolAddress,
            data: swapData,  
            callback: address(0),  
            callbackData: "0x"  
        });

        ISyncRouter.SwapPath[] memory paths = new ISyncRouter.SwapPath[](1);
        paths[0] = ISyncRouter.SwapPath({
            steps: new ISyncRouter.SwapStep[](1),
            tokenIn: tokenIn,
            amountIn: amountIn
        });

        paths[0].steps[0] = step;
        uint deadline = block.timestamp + 20 minutes; 
        IPool.TokenAmount memory amountOut = syncRouter.swap(
            paths,
            0,
            deadline
        );
        emit SwapExecuted(msg.sender, tokenIn, amountOut.token, amountIn, amountOut.amount, 1);
        return amountOut;
    }

    /**
     * @notice Executes a token swap using the specified tokenIn, tokenOut, amountIn, and amountOutMin.
     * @dev Internal function used by executeSwaps.
     * @param tokenIn Address of the input token.
     * @param tokenOut Address of the output token.
     * @param amountIn Amount of input token to swap.
     * @return A struct containing the address of the output token and the amount of output tokens received.
     */
    function echoDex(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) internal returns (IPool.TokenAmount memory) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint deadline = block.timestamp + 20 minutes; 
        uint[] memory amounts = echoRouter.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );

        IPool.TokenAmount memory tokenOutAmount;
        tokenOutAmount.token = tokenOut;
        tokenOutAmount.amount = amounts[amounts.length - 1];
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amounts[amounts.length - 1], 3);
        return tokenOutAmount;
    }

    /**
     * @notice Executes a series of swap operations based on the provided swapParams.
     * @dev This function performs chained swaps using syncswap, horizondex and echodex functions.
     * @param swapParams Array of SwapParam structures containing swap details.
     * @param minTotalAmountOut Minimum total amount of output token expected.
     */
    function executeSwaps(Params.SwapParam[] memory swapParams, uint minTotalAmountOut) nonReentrant() external {
        address tokenG = swapParams[0].tokenIn;
        IERC20 token = IERC20(tokenG);
        uint256 amountIn = swapParams[0].amountIn;
        if (!token.transferFrom(msg.sender ,address(this), amountIn)) revert TransferFromFailedError(msg.sender, address(this), amountIn);
        address finalTokenAddress;
        uint finalTokenAmount;
        for(uint i = 0; i < swapParams.length; i++) {
            Params.SwapParam memory param = swapParams[i];
            if(param.swapType == 1) {
                IPool.TokenAmount memory result = syncswap(
                    param.poolAddress, 
                    param.tokenIn, 
                    amountIn
                );
                finalTokenAddress = result.token;
                finalTokenAmount = result.amount;
            } else if(param.swapType == 2) {
                IPool.TokenAmount memory result = horizonDex(
                    param.tokenIn, 
                    param.tokenOut, 
                    param.fee,
                    amountIn
                );
                finalTokenAddress = result.token;
                finalTokenAmount = result.amount;
            } else if(param.swapType == 3) {
                IPool.TokenAmount memory result = echoDex(
                    param.tokenIn, 
                    param.tokenOut, 
                    amountIn
                );
                finalTokenAddress = result.token;
                finalTokenAmount = result.amount;
            } else {
                revert("Invalid swap type");
            }
            amountIn = finalTokenAmount;
        }
        if(finalTokenAmount < minTotalAmountOut) revert AmountLessThanMinRequiredError(finalTokenAmount, minTotalAmountOut);
        IERC20 finalToken = IERC20(finalTokenAddress);
        uint fee = (finalTokenAmount * 3) / 1000;
        uint amountToTransfer = finalTokenAmount - fee;
        if(!finalToken.transfer(_fee_address, fee)) revert TransferFailedError(finalTokenAddress, _fee_address, fee);
        if(!finalToken.transfer(msg.sender, amountToTransfer)) revert TransferFailedError(finalTokenAddress, msg.sender, amountToTransfer);
    
        emit PathsExecuted(msg.sender, swapParams, minTotalAmountOut, finalTokenAmount);
    }
}

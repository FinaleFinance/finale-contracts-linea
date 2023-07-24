const { chai, expect } = require("chai");
const hre = require("hardhat");
let finale;
let deployer;

describe("Finale Contract", function () {
  this.timeout(0);
  before(async function() {
    [deployer] = await hre.ethers.getSigners();
    const Finale = await hre.ethers.getContractFactory("Finale");
    finale = await Finale.deploy();
    expect(finale.address).to.exist;
  });

  it("Should set fee percentage correctly", async function () {
    // Set a new fee percentage
    const newFeePercentage = hre.ethers.BigNumber.from("5"); // Adjust this as necessary, but it should be less than 2^24.
    await finale.setFeePercentage(newFeePercentage);
  
    // Get the current fee percentage
    const currentFeePercentage = await finale.feePercentage();
  
    // Check that the fee percentage has been updated correctly
    expect(currentFeePercentage).to.deep.equal(newFeePercentage);
  });
  
  it("Should set fee address correctly", async function () {
    // Get the second address from the signers
    const [, newFeeAddress] = await hre.ethers.getSigners();

    await finale.setFeeAddress(newFeeAddress.address);
  
    // Get the current fee address
    const currentFeeAddress = await finale.fee_address();
  
    // Check that the fee address has been updated correctly
    expect(currentFeeAddress).to.equal(newFeeAddress.address);
  });

  it("Should set max approvals correctly", async function () {
    const tokenAddress1 = "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f";
    const tokenAddress2 = "0x7d43AABC515C356145049227CeE54B608342c0ad";

    await finale.maxApprovals([tokenAddress1, tokenAddress2]);

    // Get the contract of the tokens
    const Token1 = await hre.ethers.getContractAt("IERC20", tokenAddress1);
    const Token2 = await hre.ethers.getContractAt("IERC20", tokenAddress2);
  
    // Get the router addresses from the contract
    const routerAddresses = [
      await finale.syncrouterAddress(),
      await finale.horizonrouterAddress(),
      await finale.echoRouterAddress(),
      await finale.leetswapRouterAddress()
    ];

    // Check the allowance of the contract address for each token and router
    for (const routerAddress of routerAddresses) {
      const allowance1 = await Token1.allowance(finale.address, routerAddress);
      const allowance2 = await Token2.allowance(finale.address, routerAddress);

      // Check that the allowance is set to the maximum value
      expect(allowance1).to.deep.equal(hre.ethers.constants.MaxUint256);
      expect(allowance2).to.deep.equal(hre.ethers.constants.MaxUint256);
  }
  });

  it("Should execute swaps correctly", async function () {
    const value = hre.ethers.utils.parseEther("1");
    // Swap params
    const swapParams = [
      {
        "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
        "tokenIn": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
        "tokenOut": "0x7d43AABC515C356145049227CeE54B608342c0ad",
        "amountIn": value,
        "amountOutMin": 0,
        "fee": 300,
        "swapType": 1
    },
    {
      "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
      "tokenIn": "0x7d43AABC515C356145049227CeE54B608342c0ad",
      "tokenOut": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
      "amountIn": 0,
      "amountOutMin": 0,
      "fee": 300,
      "swapType": 2
    },
    {
      "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
      "tokenIn": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
      "tokenOut": "0x7d43AABC515C356145049227CeE54B608342c0ad",
      "amountIn": 0,
      "amountOutMin": 0,
      "fee": 300,
      "swapType": 3
    },
    {
      "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
      "tokenIn": "0x7d43AABC515C356145049227CeE54B608342c0ad",
      "tokenOut": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
      "amountIn": 0,
      "amountOutMin": 0,
      "fee": 300,
      "swapType": 4
    }
    ];

    // Get the contract instances for the tokens
    const TokenIn = await hre.ethers.getContractAt("IERC20", swapParams[0].tokenIn);
    const TokenOut = await hre.ethers.getContractAt("IERC20", swapParams[0].tokenOut);

    // Get the initial balances
    const initialBalanceIn = await TokenIn.balanceOf(deployer.address);
    const initialBalanceOut = await TokenOut.balanceOf(deployer.address);

    const minTotalAmountOut = hre.ethers.BigNumber.from(0);

    let tx = await finale.executeSwaps(swapParams, minTotalAmountOut, { value: value });
    let receipt = await tx.wait();
    // The 'find' function is used to find the 'PathsExecuted' event in the array of events from the receipt.
    // This event is emitted when the swaps have been executed and it contains the total output amount.
    let event = receipt.events?.find(e => e.event === 'PathsExecuted');
    const totalOut = event.args[event.args.length - 1];

    // Approve the Finale contract to spend the tokens on behalf of the deployer
    await TokenIn.connect(deployer).approve(finale.address, totalOut.div(2));

    // Assert the total output amount
    expect(totalOut.gte(minTotalAmountOut)).to.be.true;
    // Prepare the next swap params
    const additionalSwapParams = [
      {
        "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
        "tokenIn": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
        "tokenOut": "0x7d43AABC515C356145049227CeE54B608342c0ad",
        "amountIn": totalOut.div(2),
        "amountOutMin": 0,
        "fee": 300,
        "swapType": 1
      },
      {
        "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
        "tokenIn": "0x7d43AABC515C356145049227CeE54B608342c0ad",
        "tokenOut": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
        "amountIn": 0,
        "amountOutMin": 0,
        "fee": 300,
        "swapType": 2
      },
      {
        "poolAddress": "0x7f72e0d8e9abf9133a92322b8b50bd8e0f9dcfcb",
        "tokenIn": "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f",
        "tokenOut": "0x7d43AABC515C356145049227CeE54B608342c0ad",
        "amountIn": 0,
        "amountOutMin": 0,
        "fee": 300,
        "swapType": 3
      }
    ];

    // Execute the additional swaps
    tx = await finale.executeSwaps(additionalSwapParams, minTotalAmountOut);
    receipt = await tx.wait();
    // The 'find' function is used to find the 'PathsExecuted' event in the array of events from the receipt.
    // This event is emitted when the swaps have been executed and it contains the total output amount.
    event = receipt.events?.find(e => e.event === 'PathsExecuted');
    const additionalTotalOut = event.args[event.args.length - 1];
    // Assert the total output amount of the additional swaps
    expect(additionalTotalOut.gte(minTotalAmountOut)).to.be.true;

    // Get the final balances
    const finalBalanceIn = await TokenIn.balanceOf(deployer.address);
    const finalBalanceOut = await TokenOut.balanceOf(deployer.address);
    expect(finalBalanceIn.gt(initialBalanceIn)).to.be.true; // TokenIn balance should increase
    expect(finalBalanceOut.gt(initialBalanceOut)).to.be.true; // TokenOut balance should increase
  });

  it("Should set revoke approvals correctly", async function () {
    const tokenAddress1 = "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f";
    const tokenAddress2 = "0x7d43AABC515C356145049227CeE54B608342c0ad";

    await finale.revokeApprovals([tokenAddress1, tokenAddress2]);

    // Get the contract of the tokens
    const Token1 = await hre.ethers.getContractAt("IERC20", tokenAddress1);
    const Token2 = await hre.ethers.getContractAt("IERC20", tokenAddress2);
  
    // Get the router addresses from the contract
    const routerAddresses = [
      await finale.syncrouterAddress(),
      await finale.horizonrouterAddress(),
      await finale.echoRouterAddress(),
      await finale.leetswapRouterAddress()
    ];

    // Check the allowance of the contract address for each token and router
    for (const routerAddress of routerAddresses) {
      const allowance1 = await Token1.allowance(finale.address, routerAddress);
      const allowance2 = await Token2.allowance(finale.address, routerAddress);

      // Check that the allowance is set to the 0 value
      expect(allowance1.eq(hre.ethers.constants.Zero)).to.be.true;
      expect(allowance2.eq(hre.ethers.constants.Zero)).to.be.true;

  }
  });
  
});

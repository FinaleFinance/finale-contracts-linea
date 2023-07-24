# Finale Smart Contract Test Suite

This repository houses the test suite for the Finale smart contract. Developed for the Linea blockchain, this suite is instrumental in validating the contract's correct operation and expected interactions. The `test.js` script written in JavaScript utilizes the [Hardhat](https://hardhat.org/) Ethereum development environment and the [Chai](https://www.chaijs.com/) assertion library for testing.

## Test Overview

The `test.js` script comprises five primary tests:

1. **"Should set fee percentage correctly"**: This test verifies the smart contract's ability to accurately set the fee percentage. It updates this value and subsequently verifies the change by cross-referencing the set fee percentage with the expected fee percentage.

2. **"Should set fee address correctly"**: This test checks the smart contract's functionality to set the fee address correctly. It updates the fee address and then validates the change by comparing the set fee address with the expected one.

3. **"Should set max approvals correctly"**: This test evaluates whether the smart contract correctly sets maximum approval values for tokens for different routers. It verifies this by checking if the contract's allowance for each token and router is indeed set to the maximum value.

4. **"Should execute swaps correctly"**: This test assesses whether the smart contract accurately executes token swaps. It prepares swap parameters, initiates the swaps, and then confirms whether the swaps were conducted correctly by examining the total output amount and the balances of tokens involved in the swaps.

5. **"Should set revoke approvals correctly"**: This test ascertains the smart contract's capacity to revoke approvals accurately for different tokens and routers. It confirms this by checking if the contract's allowance for each token and router is reset to zero.

These tests collectively ensure the proper functionality of the Finale smart contract, providing a high degree of confidence that the contract will operate as expected when deployed on the Ethereum blockchain.

## Installation

Before running these tests, you must install Hardhat and Chai. If you have not installed these, you can do so with the following commands:

```bash
npm install --save-dev hardhat
npm install --save-dev chai
```

## Running the Tests

Upon successful installation of the necessary dependencies, you can run the tests with the following command:

```bash
npx hardhat test
```

This command initiates the Hardhat test runner, which executes the `test.js` script.

Please note that due to the nature of these tests, they may take some time to complete. It's important to let them finish to ensure all aspects of the smart contract are thoroughly checked.

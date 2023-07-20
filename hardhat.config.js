require("@nomiclabs/hardhat-ethers");

module.exports = {
    networks: {
      hardhat: {
        forking: {
          url: "https://linea-mainnet.infura.io/v3/API_KEY",
          blockNumber: 9000
        }
      }
    },
    solidity: {
      version: "0.8.17", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  };
  
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  let Contract, contract, transaction;
  Contract = await hre.ethers.getContractFactory("Finale");
  contract = await Contract.deploy();

  console.log("Contract deployed to:", contract.address);
  
  const contractAddress = contract.address; 
  const tokenAddresses = ["0x7d43aabc515c356145049227cee54b608342c0ad", "0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f"]; 
  
  Contract = await hre.ethers.getContractFactory("Finale");
  contract = await Contract.attach(contractAddress);
  
  console.log("Calling maxApprovals function with the account:", deployer.address);
  transaction = await contract.maxApprovals(tokenAddresses);
  await transaction.wait();

  console.log("maxApprovals function called successfully.");

  console.log("Calling revokeApprovals function with the account:", deployer.address);
  transaction = await contract.revokeApprovals(tokenAddresses);
  await transaction.wait();

  console.log("revokeApprovals function called successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

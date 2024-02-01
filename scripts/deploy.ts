// deployments/01_deploy_fee_splitting_contract.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy FeeSplittingContract
  const FeeSplittingContract = await ethers.getContractFactory(
    "FeeSplittingContract"
  );
  const feeSplittingContract = await FeeSplittingContract.deploy(
    deployer.address,
    5
  );
  // await feeSplittingContract.deployed();

  console.log(
    "FeeSplittingContract deployed to:",
    await feeSplittingContract.getAddress()
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

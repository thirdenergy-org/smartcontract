require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const CrowdfundStation = await ethers.getContractFactory("CrowdfundStation");
  const [deployer] = await ethers.getSigners();
  const owner = await deployer.getAddress();

  const provider = ethers.provider;
  const block = await provider.getBlock("latest");
  const endTime = Number(block.timestamp) + 60 * 24 * 60 * 60;

  const station = await CrowdfundStation.deploy(
    "Mamu Village Micro Station",
    "MAMU-IIIENERGY",
    process.env.ACCOUNT_EVM,
    50_000 * 1e8,
    endTime
  );
  await station.waitForDeployment();

  const deployedAddress = await station.getAddress();

  console.log(deployedAddress);
}

main();

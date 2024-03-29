const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------------------------------");

  await deploy("RaffleERC20", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });

  // Verify the deployment
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log("Verifying...");
    await verify(raffleERC20.address, []);
    log("Verification successfull!");
  }
};

module.exports.tags = ["all", "raffleERC20"];

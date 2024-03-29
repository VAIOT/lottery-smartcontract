const { ethers } = require("hardhat");

const networkConfig = {
  default: {
    name: "hardhat",
  },
  31337: {
    name: "localhost",
    subscriptionId: "2679",
    gasLane:
      "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", // 30 gwei
    callbackGasLimit: "25000000", // 2,500,000 gas
  },
  80001: {
    name: "mumbai",
    subscriptionId: "2679",
    gasLane:
      "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", // 30 gwei
    callbackGasLimit: "2500000", // 2,500,000 gas
  },
  137: {
    name: "polygon",
    subscriptionId: "621",
    gasLane:
      "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd", // 500 gwei
    callbackGasLimit: "2500000", // 2,500,000 gas
  },
};

const developmentChains = ["hardhat", "localhost"];
const VERIFICATION_BLOCK_CONFIRMATIONS = 6;

module.exports = {
  networkConfig,
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
};

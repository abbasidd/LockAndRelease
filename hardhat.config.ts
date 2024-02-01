import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.4.17",
      },
      {
        version: "0.8.20",
      },
      {
        version: "0.7.0",
      },
    ],
  },
};

export default config;

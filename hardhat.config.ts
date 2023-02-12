require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-waffle");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_POLYGON_URL = process.env.ALCHEMY_POLYGON_URL;
const POLYGON_SCAN_KEY = process.env.POLYGON_SCAN_KEY;
const AVALANCHE_URL = process.env.AVALANCHE_URL;
const AVALANCHE_SNOWTRACE_KEY = process.env.AVALANCHE_SNOWTRACE_KEY;

module.exports = {
  solidity: "0.8.18",
  networks: {
    mumbai: {
      url: ALCHEMY_POLYGON_URL,
      accounts: [PRIVATE_KEY],
    },
    fuji: {
      url: AVALANCHE_URL,
      accounts: [PRIVATE_KEY],
      chainId: 43113,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: POLYGON_SCAN_KEY,
      avalancheFujiTestnet: AVALANCHE_SNOWTRACE_KEY,
    },
  },
};

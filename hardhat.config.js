require("@nomicfoundation/hardhat-toolbox");
const { config } = require('dotenv')
config({ path: `.env` });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: "https://rpc.ankr.com/eth_sepolia",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155111
    }
  },
  sourcify: {
    enabled: true
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

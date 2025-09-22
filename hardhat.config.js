require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: "cancun", // <-- important
    },
  },
  networks: {
    "hedera-testnet": {
      url: `https://testnet.hashio.io/api`,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};

require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
require('dotenv').config({path:__dirname+'/.env'});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.11",
  defaultNetwork: "hardhat",
  networks: {
    hardhat:{},
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`${process.env.MAIN_DEPLOYMENT_ACCOUNT_PRIVATE_KEY}`] ,
      gasPrice:100000000000,
      timeout:40000000,
    },
    local: {
      url: `http://localhost:7545`,
      accounts: [`${process.env.LOCAL_DEPLOYMENT_ACCOUNT_PRIVATE_KEY}`] ,
      gasPrice:100000000000,
      timeout:40000000,
    },

  },
  // settings:{
  //   optimizer: {
  //     enabled: true,
  //     runs: 20,
  //   },
  // }, 
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  }
};

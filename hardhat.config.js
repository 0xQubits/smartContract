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
    hardhat: {/* allowUnlimitedContractSize:true*/},
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_API_KEY}`,
      accounts: [`${process.env.ROPSTEN_PRIVATE_KEY}`] ,
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
  },
};

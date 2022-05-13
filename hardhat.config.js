require("@nomiclabs/hardhat-waffle");
require('dotenv').config({path:__dirname+'/.env'});

console.log(__dirname+'/.env')
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.11",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // allowUnlimitedContractSize:true
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_API_KEY}`,
      accounts: [`${process.env.ROPSTEN_PRIVATE_KEY}`] 
    }
  },
};

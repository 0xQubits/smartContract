require("@nomiclabs/hardhat-waffle");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const ROPSTEN_API_KEY = "c721fceec23a47078e3213d3d0bbc820";
const ROPSTEN_PRIVATE_KEY = "f102da1847a2e425063fc4e96ea7981ce66b21ebf8d2e92da800409764670e00";
module.exports = {
  solidity: "0.8.11",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // allowUnlimitedContractSize:true
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${ROPSTEN_API_KEY}`,
      accounts: [`${ROPSTEN_PRIVATE_KEY}`]
    }
  },
};

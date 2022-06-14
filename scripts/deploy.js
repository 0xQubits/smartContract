const { ethers, upgrades } = require("hardhat");
const fs = require('fs');


async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const UtilsLibraryFactory = await ethers.getContractFactory("Utils");
  utilsLibrary = await UtilsLibraryFactory.deploy();


  const InternalTokenStorageFactory = await ethers.getContractFactory("InternalTokenStorage");
  const ExternalTokenStorageFactory = await ethers.getContractFactory("ExternalTokenStorage");
  const ActiveTokenStorageFactory = await ethers.getContractFactory("ActiveTokenStorage");


  internalTokenStorage = await upgrades.deployProxy(InternalTokenStorageFactory);
  externalTokenStorage = await upgrades.deployProxy(ExternalTokenStorageFactory);
  activeTokenStorage = await upgrades.deployProxy(ActiveTokenStorageFactory);

  const QubitsFactory = await ethers.getContractFactory("Qubits");

  qubits = await upgrades.deployProxy(QubitsFactory, [
    internalTokenStorage.address,
    externalTokenStorage.address,
    activeTokenStorage.address
  ]);

  await qubits.deployed();
  var addressObj = JSON.stringify({
    qubits: qubits.address,
    internalTokenStorage: internalTokenStorage.address,
    externalTokenStorage: externalTokenStorage.address,
    activeTokenStorage: activeTokenStorage.address
  })
  
 
let data = JSON.stringify(addressObj);
fs.writeFileSync('deployedAddresses.json', data);
console.log("\n\n\n Deployment complete! \n\n\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
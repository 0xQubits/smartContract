const { ethers, upgrades } = require("hardhat");
const fs = require('fs');


async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const UtilsLibraryFactory = await ethers.getContractFactory("Utils");
  utilsLibrary = await UtilsLibraryFactory.deploy();


  const QubitsTokenRegistryFactory = await ethers.getContractFactory("QubitsTokenRegistry");
  const OtherTokenRegistryFactory = await ethers.getContractFactory("OtherTokenRegistry");
  const UserQubitsTokenRegistryFactory = await ethers.getContractFactory("UserQubitsTokenRegistry");


  const qubitsTokenRegistry = await upgrades.deployProxy(QubitsTokenRegistryFactory);
  const otherTokenRegistry = await upgrades.deployProxy(OtherTokenRegistryFactory);
  const userQubitsTokenRegistry = await upgrades.deployProxy(UserQubitsTokenRegistryFactory);

  const QubitsFactory = await ethers.getContractFactory("Qubits");

  const qubits = await upgrades.deployProxy(QubitsFactory, [
    qubitsTokenRegistry.address,
    otherTokenRegistry.address,
    userQubitsTokenRegistry.address
  ]);

  await qubits.deployed();

  await qubitsTokenRegistry.setRegistryAdmin(
    qubits.address
)
  await otherTokenRegistry.setRegistryAdmin(
      qubits.address
  )
  await userQubitsTokenRegistry.setRegistryAdmin(
      qubits.address
  )
  var addressObj = JSON.stringify({
    qubits: qubits.address,
    qubitsTokenRegistry: qubitsTokenRegistry.address,
    otherTokenRegistry: otherTokenRegistry.address,
    userQubitsTokenRegistry: userQubitsTokenRegistry.address
  })

  
 
let data = JSON.parse(JSON.stringify(addressObj)) ;
  const {chainId} = (await ethers.getSigner())._signer.provider._network

fs.writeFileSync(`deployedAddresses-${chainId}.json`, data);
console.log("\n\n\n Deployment complete! \n\n\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
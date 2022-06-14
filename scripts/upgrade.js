const { ethers, upgrades } = require("hardhat");
const fs = require('fs');


async function main() {
      const [deployer] = await ethers.getSigners();

    const data = fs.readFileSync('./deployedAddresses.json',
        { encoding: 'utf8'});
    const addressObj = JSON.parse(data);


    console.log("Upgrading contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());


    const InternalTokenStorageFactory = await ethers.getContractFactory("InternalTokenStorage");
    const ExternalTokenStorageFactory = await ethers.getContractFactory("ExternalTokenStorage");
    const ActiveTokenStorageFactory = await ethers.getContractFactory("ActiveTokenStorage");
    const QubitsFactory = await ethers.getContractFactory("Qubits");
    // get type of variable

    internalTokenStorage = await upgrades.upgradeProxy(
        addressObj.internalTokenStorage,
        InternalTokenStorageFactory
    );
    // externalTokenStorage = await upgrades.upgradeProxy(
    //     addressObj.externalTokenStorage,
    //     ExternalTokenStorageFactory
    // );
    // activeTokenStorage = await upgrades.upgradeProxy(
    //     addressObj.activeTokenStorage,
    //     ActiveTokenStorageFactory
    // // );
    // qubits = await upgrades.upgradeProxy(
    //     addressObj.qubits,
    //     QubitsFactory
    // );

    console.log("\n\n\n Upgrade complete! \n\n\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
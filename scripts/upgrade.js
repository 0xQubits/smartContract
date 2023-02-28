const { ethers, upgrades } = require("hardhat");
const fs = require('fs');


async function main() {
      const [deployer] = await ethers.getSigners();

    const data = fs.readFileSync('./deployedAddresses.json',
        { encoding: 'utf8'});
    const addressObj = JSON.parse(data);


    console.log("Upgrading contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());


    const QubitsTokenRegistryFactory = await ethers.getContractFactory("QubitsTokenRegistry");
    const OtherTokenRegistryFactory = await ethers.getContractFactory("OtherTokenRegistry");
    const UserQubitsTokenRegistryFactory = await ethers.getContractFactory("UserQubitsTokenRegistry");
    const QubitsFactory = await ethers.getContractFactory("Qubits");
    // get type of variable

    internalTokenStorage = await upgrades.upgradeProxy(
        addressObj.internalTokenStorage,
        QubitsTokenRegistryFactory
    );
    // externalTokenStorage = await upgrades.upgradeProxy(
    //     addressObj.externalTokenStorage,
    //     OtherTokenRegistryFactory
    // );
    // activeTokenStorage = await upgrades.upgradeProxy(
    //     addressObj.activeTokenStorage,
    //     UserQubitsTokenRegistryFactory
    // // );
    // qubits = await upgrades.upgradeProxy(
    //     addressObj.qubits,
    //     QubitsFactory
    // );

    // await qubitsTokenRegistry.setRegistryCaller(
    //     qubits.address
    // )
    //   await otherTokenRegistry.setRegistryCaller(
    //       qubits.address
    //   )
    //   await userQubitsTokenRegistry.setRegistryCaller(
    //       qubits.address
    //   )

    console.log("\n\n\n Upgrade complete! \n\n\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
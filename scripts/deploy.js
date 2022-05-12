async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Quantum = await ethers.getContractFactory("Quantum");
    const quantum = await Quantum.deploy();
    // const Game = await ethers.getContractFactory("Game");
    // const game = await Game.deploy();
  
    console.log("Quantum Contract address:", quantum.address);
    // console.log("Game Contract address:", quantum.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Qubits = await ethers.getContractFactory("Qubits");
    const qubits = await Qubits.deploy();
    // const Game = await ethers.getContractFactory("Game");
    // const game = await Game.deploy();
  
    console.log("Qubits Contract address:", qubits.address);
    // console.log("Game Contract address:", game.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
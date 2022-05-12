async function main() {
    const [sender] = await ethers.getSigners();
  
    
    const Quantum = await ethers.getContractFactory("Quantum");
    const quantum = await Quantum.attach("0xdDbc6c0B82Bdf20ef700Ca4F8736e0C62526E1B3");


    const Game = await ethers.getContractFactory("Game");
    const game = await Game.attach("0x19f6d2E4Cb2e228fb9cEE518fe4FBffE3B7289bD");
    // const mintGameTx = await game.awardItem(sender.address);
    // await mintGameTx.wait();
    
    // gameTokenId = 4;
    // let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,gameTokenId);
    // await safeTransferTx.wait();
    
    new_owners = ["0xf8869fD097741977Ec64b4b2A493B297598eb623",sender.address];
    new_owners_portion = [9 * 10 ** 11, 1 * 10 ** 11];
    let divisionTx = await quantum.splitTokenOwnership(0,new_owners,new_owners_portion);
    r = await divisionTx.wait()
    

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
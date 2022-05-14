async function main() {
    const [sender] = await ethers.getSigners();
  
    
    const Quantum = await ethers.getContractFactory("Quantum");
    const quantum = await Quantum.attach("0x277B336C58fbE062167f126AD90b06d43dd7fe29");


    // const Game = await ethers.getContractFactory("Game");
    // const game = await Game.attach("0x80797184053baa621915faa580e3d596fc2edad9");
    // const mintGameTx = await game.awardItem(sender.address);
    // await mintGameTx.wait();
    
    // gameTokenId = 4;
    // let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,gameTokenId);
    // await safeTransferTx.wait();
    
    let externalTokenHash = "0x9517c768089db27b1ec29b54ee5cf0b734973de14432d4d85111534d3f8061b5"
    
    let tx = await quantum.returnToken(externalTokenHash);
    r = await tx.wait()
    console.log(r)
    

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
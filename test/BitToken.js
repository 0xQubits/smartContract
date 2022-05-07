const { expect } = require("chai");

let bitToken;
let game;
let owner;
let addr1;
let addr2;
let addr3;
let addrs;
before(async function () {
    
    [owner, addr1, addr2,addr3, ...addrs] = await ethers.getSigners();

    const BitToken = await ethers.getContractFactory("BitToken");
    bitToken = await BitToken.deploy();
    const Game = await ethers.getContractFactory("Game");
    game = await Game.deploy();
    await bitToken.deployed();
    await game.deployed();

    const mintGameTx = await game.awardItem(owner.address);
    await mintGameTx.wait();
    expect(await game.ownerOf(1)).to.equal(owner.address);
  });



describe("Initialization", function () {
  it("Should send a token representing 100% ownership to the NFT sender when it receives an NFT", async function () {
    // Ensure that the NFT can be sent to the BitToken contract
    // and 100% ownership is originally assigned to the sender of the NFT
    let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](owner.address,bitToken.address,1);
    await safeTransferTx.wait()
    
    let originalToken = await bitToken.getOriginalToken(game.address,1);
    expect(originalToken.contract_ ).to.equal(game.address);
    expect(originalToken.sender ).to.equal(owner.address);


    let dividedToken = await bitToken.getDividedToken(0);
    expect(dividedToken.owner).to.equal(owner.address);
    expect(dividedToken.portion).to.equal(10**12);
    expect(dividedToken.has_been_altered).to.equal(false);
  });  
});



describe("Split", function () {
     
    it("Should send percentage of the original token to new owners", async function () {
        // Ensure that the NFT can be further divided
        // ensure that it is sent to the intended new owners 
        let new_owners = [owner.address,addr1.address,addr2.address,addr3.address]
        let new_owners_portion = [
            1 * 10 ** 11,
            3 * 10 ** 11,
            2 * 10 ** 11,
            4 * 10 ** 11,
        ]
        
        let divisionTx = await bitToken.divideToken(0,new_owners,new_owners_portion);
        res = await divisionTx.wait()
        console.log(res.events)
        

        let divided_token = await bitToken.getDividedToken(0); 
        expect(divided_token.has_been_altered, true, "The first divided token should now be altered");

        for (i=1; i < 5 ;i++){
            let new_divided_token = await bitToken.getDividedToken(i);
            expect(new_divided_token.owner).to.equal(new_owners[i-1])
            expect(new_divided_token.portion).to.equal(new_owners_portion[i-1]);
            expect(new_divided_token.has_been_altered).to.equal(false);

        }
    });






    it("Should further divide a formerly divided token and send to new owners", async function () {
        // Ensure that the NFT can be further divided
        // ensure that it is sent to the intended new owners 
        let new_owners = [owner.address,addr1.address]
        let new_owners_portion = [5 * 10 ** 10,5 * 10 ** 10]
        owners_token_id = 1
        let divisionTx = await bitToken.divideToken(owners_token_id,new_owners,new_owners_portion);
        await divisionTx.wait()


        let divided_token = await bitToken.getDividedToken(owners_token_id); 
        expect(divided_token.has_been_altered, true, "The first divided token should now be altered");

        for (i=5; i < 7 ;i++){
            let new_divided_token = await bitToken.getDividedToken(i);
            expect(new_divided_token.owner).to.equal(new_owners[i-5])
            expect(new_divided_token.portion).to.equal(new_owners_portion[i-5]);
            expect(new_divided_token.has_been_altered).to.equal(false);

        }
    });


  });
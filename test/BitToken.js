// This document does not in any way showcase my 
// modularity or abstraction or organizational skills
// I'm just testing stuff out
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

let testTotal  = (activeTokens)=> {
    let total = 0
    for (i of activeTokens){
        total+=i.portion.toNumber()
    }
    expect(total).to.equal(10**12)
}


describe("Initialization", function () {
    it("Should send a token representing 100% ownership to the NFT sender when it receives an NFT", async function () {
        // Ensure that the NFT can be sent to the BitToken contract
        // and 100% ownership is originally assigned to the sender of the NFT
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](owner.address,bitToken.address,1);
        await safeTransferTx.wait()

        expect(await game.ownerOf(1)).to.equal(bitToken.address);

    
        
        // expect(externalToken.contract_ ).to.equal(game.address);
        // expect(externalToken.sender ).to.equal(owner.address);


        let token = await bitToken.getToken(0);
        expect(token.owner).to.equal(owner.address);
        expect(token.portion).to.equal(10**12);
        expect(token.hasBeenAltered).to.equal(false);

        let hash_value = await bitToken.makeExternalTokenHash(game.address,1)
        let activeTokens = await bitToken.getActiveTokenArr(hash_value)
        
        testTotal(activeTokens)
        
    });  
});



describe("Split", function () {
     
    it("Should send percentage of the original token to new owners", async function () {
        // Ensure that the NFT can be further divided
        // ensure that it is sent to the intended new owners 
        let externalToken = await bitToken.getExternalToken(game.address,1);
        console.log(externalToken)
        let new_owners = [owner.address,
            addr1.address,
            addr2.address,
            addr3.address
        ]
        let new_owners_portion = [
            1 * 10 ** 11,
            3 * 10 ** 11,
            2 * 10 ** 11,
            4 * 10 ** 11,
        ]
        
        let divisionTx = await bitToken.modifyTokenOwnership(0,new_owners,new_owners_portion);
        await divisionTx.wait()
        // console.log(res.events)

        

        let divided_token = await bitToken.getToken(0); 
        expect(divided_token.hasBeenAltered, true, "The first divided token should now be altered");

        for (i=1; i < 5 ;i++){
            let new_divided_token = await bitToken.getToken(i);
            expect(new_divided_token.owner).to.equal(new_owners[i-1])
            expect(new_divided_token.portion).to.equal(new_owners_portion[i-1]);
            expect(new_divided_token.hasBeenAltered).to.equal(false);

        }
        let hash_value = await bitToken.makeExternalTokenHash(game.address,1)
        let activeTokens = await bitToken.getActiveTokenArr(hash_value)
        testTotal(activeTokens)
        

    });






    it("Should further divide a formerly divided token and send to new owners", async function () {
        // Ensure that the NFT can be further divided
        // ensure that it is sent to the intended new owners 
        let new_owners = [owner.address,addr1.address]
        let new_owners_portion = [5 * 10 ** 10,5 * 10 ** 10]
        owners_token_id = 1
        let divisionTx = await bitToken.modifyTokenOwnership(owners_token_id,new_owners,new_owners_portion);
        await divisionTx.wait()

        let divided_token = await bitToken.getToken(owners_token_id); 
        expect(divided_token.hasBeenAltered, true, "The first divided token should now be altered");

        for (i=5; i < 7 ;i++){
            let new_divided_token = await bitToken.getToken(i);
            expect(new_divided_token.owner).to.equal(new_owners[i-5])
            expect(new_divided_token.portion).to.equal(new_owners_portion[i-5]);
            expect(new_divided_token.hasBeenAltered).to.equal(false);

        }
        let hash_value = await bitToken.makeExternalTokenHash(game.address,1)
        let activeTokens = await bitToken.getActiveTokenArr(hash_value)
        testTotal(activeTokens)

    });



  });
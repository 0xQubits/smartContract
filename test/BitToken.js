const { expect, assert } = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const {bigNumberToNumber,checkSumTotal} = require("./utils");

let bitToken;
let game;
let owner;
let addr1;
let addr2;
let addr3;
let addrs;
let gameTokenId;
let new_owners;
let new_owners_portion;
let startTokenIndex;
let endTokenIndex;
const MAX_PORTION = 10**12;
const MAX_INT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
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
    gameTokenId = 0;
    expect(await game.ownerOf(gameTokenId)).to.equal(owner.address);
  });





describe("Initialization", function () {

    it("Should that an external token can be sent to this contract", async function () {
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](owner.address,bitToken.address,gameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(gameTokenId)).to.equal(bitToken.address);
        
    }),  

    it("Should ensure that an ExternalToken object is created \
        and that it has all the correct properties", async function () {
        let externalTokenHash = await bitToken.makeExternalTokenHash(game.address,gameTokenId)
        let externalToken = await bitToken.getExternalToken(externalTokenHash);
        let historyArr = [0];
        let activeTokenIdsArr = [0];
        expect(externalToken.contract_ ).to.equal(game.address);
        expect(externalToken.sender ).to.equal(owner.address);
        expect(externalToken.tokenId.toNumber() ).to.equal(0);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);

    }),

    it("Should ensure that the active token array sums up to 100%  ", async function () {
        let externalTokenHash = await bitToken.makeExternalTokenHash(game.address,gameTokenId);
        checkSumTotal(externalTokenHash);
    }),

    it("Should ensure that a bitToken object is created \
        which will represent 100% ownership of the ExternalToken", async function () {
        const MAX_INT_BIGNUMBER = BigNumber.from(MAX_INT);
        
        let token = await bitToken.getToken(0);
        let externalTokenHash = await bitToken.makeExternalTokenHash(game.address,gameTokenId);
        expect(token.owner).to.equal(owner.address);
        expect(token.portion).to.equal(MAX_PORTION); 
        expect(token.hasBeenAltered).to.equal(false);
        expect(token.externalTokenHash).to.equal(externalTokenHash);
        expect(token.parentId).to.equal(MAX_INT_BIGNUMBER);
        
    })   
    
});



describe("Split", function () {
    let splitTokenId = 0;
    
    
    it("Should send percentage of a token to new owners", async function () {
        new_owners = [owner.address,addr1.address,
            addr2.address,addr3.address];
        new_owners_portion = [1 * 10 ** 11, 3 * 10 ** 11,
                              2 * 10 ** 11, 4 * 10 ** 11];
        let divisionTx = await bitToken.splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
            
        for (newOwner of new_owners){            
            expect(divisionTx).to.emit(bitToken, 'OwnershipModified')
            .withArgs(owner.address, newOwner.address, gameTokenId);
        };
       
    })
    postSplitTests(splitTokenId);


});




describe("Further split", function () {
    let splitTokenId = 1;
    

    
    it("Should send percentage of a token to new owners", async function () {
        new_owners = [owner.address,addr1.address]
        new_owners_portion = [5 * 10 ** 10,5 * 10 ** 10]
        let divisionTx = await bitToken.splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
        for (newOwner of new_owners){            
            expect(divisionTx).to.emit(bitToken, 'OwnershipModified')
            .withArgs(owner.address, newOwner.address, gameTokenId);
        };
    
    })
    
    postSplitTests(splitTokenId);

    
});


describe("Further split with different account", function () {
    let splitTokenId = 2;
    
    it("Should send percentage of a token to new owners", async function () {
        owner = addr1
        new_owners = [owner.address,addr2.address]
        new_owners_portion = [2 * 10 ** 11,1 * 10 ** 11]
        let divisionTx = await bitToken.connect(owner).splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
        for (newOwner of new_owners){            
            expect(divisionTx).to.emit(bitToken, 'OwnershipModified')
            .withArgs(owner.address, newOwner.address, gameTokenId);
        };
        

    })
    postSplitTests(splitTokenId);

    
    
});

    



function postSplitTests(splitTokenId) {

    it("Should ensure that the altered token\
        is no longer modifiable", async function () {
        
        let dividedToken = await bitToken.getToken(splitTokenId); 
        expect(dividedToken.hasBeenAltered, true, "The token should be altered");
    }),


    it("Should ensure that the split token\
        got to the intended beneficiaries", async function () {
        startTokenIndex = endTokenIndex;
        endTokenIndex = startTokenIndex + new_owners.length;
        for (i=startTokenIndex; i < endTokenIndex ;i++){
            let newOwner = new_owners[i-startTokenIndex];
            let newOwnerPortion = new_owners_portion[i-startTokenIndex];
            let newToken = await bitToken.getToken(i);
            let externalTokenHash = await bitToken.makeExternalTokenHash(game.address,gameTokenId);

            expect(newToken.owner).to.equal(newOwner)
            expect(newToken.portion).to.equal(newOwnerPortion);
            expect(newToken.hasBeenAltered).to.equal(false);
            expect(newToken.externalTokenHash).to.equal(externalTokenHash);
            expect(newToken.parentId.toNumber()).to.equal(splitTokenId);
         
        };
    }),


        
    it("Should ensure that the active token array sums up to 100%  ", async function () {
        let externalTokenHash = await bitToken.makeExternalTokenHash(game.address,gameTokenId);
        checkSumTotal(externalTokenHash);
    })

}
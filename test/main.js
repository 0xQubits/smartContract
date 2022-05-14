const { expect} = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { AddressZero } = require("@ethersproject/constants");
const { utils } = require("ethers");
const {bigNumberToNumber,checkSumTotal} = require("./utils");

let quantum;
let game;
let addr0;
let addr1;
let addr2;
let addr3;
let addrs;
let firstGameTokenId;
let secondGameTokenId;
let thirdGameTokenId;
let new_owners;
let new_owners_portion;
let startTokenIndex;
let endTokenIndex;
const MAX_PORTION = 10**12;
const MAX_INT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
const MINTER_ROLE = "0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a"
before(async function () {
    
    [addr0, addr1, addr2,addr3, ...addrs] = await ethers.getSigners();
    let sender = addr0;

    const Quantum = await ethers.getContractFactory("Quantum");
    quantum = await Quantum.deploy();
    const Game = await ethers.getContractFactory("Game");
    game = await Game.deploy();
    await quantum.deployed();
    await game.deployed();
    console.log("Game ",game.address)
    console.log("Quantum ",quantum.address)
 
    const mintGameTx = await game.awardItem(sender.address);
    await mintGameTx.wait();
    const mintGameTx2 = await game.awardItem(sender.address);
    await mintGameTx2.wait();
    const mintGameTx3 = await game.awardItem(sender.address);
    await mintGameTx3.wait();
    firstGameTokenId = 0;
    secondGameTokenId = 1;
    thirdGameTokenId = 2;
    expect(await game.ownerOf(firstGameTokenId)).to.equal(sender.address);
    expect(await game.ownerOf(secondGameTokenId)).to.equal(sender.address);
    expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);
  });





describe("Initialization", function () {
    

    it("Should that an external token can be sent to this contract", async function () {
        let sender = addr0;
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,firstGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(firstGameTokenId)).to.equal(quantum.address);
        
    }),  
   
    
    it("Should ensure that a Quantum token object is created \
        which will represent 100% ownership of the ExternalToken", async function () {
        const MAX_INT_BIGNUMBER = BigNumber.from(MAX_INT);
        let sender = addr0;
        let token = await quantum.TokenMap(0);
        let externalTokenHash = await quantum.makeExternalTokenHash(game.address,firstGameTokenId);
        expect(token.owner).to.equal(sender.address);
        expect(token.portion).to.equal(MAX_PORTION); 
        expect(token.hasBeenAltered).to.equal(false);
        expect(token.externalTokenHash).to.equal(externalTokenHash);
        expect(token.parentId).to.equal(MAX_INT_BIGNUMBER);

        
    }),

    it("Should ensure that basic ExternalToken data is accurate", async function () {
        let sender = addr0;
        let externalTokenHash = await quantum.makeExternalTokenHash(game.address,firstGameTokenId);
        let externalToken = await quantum.getExternalToken(externalTokenHash)
        
        expect(externalToken.contract_ ).to.equal(game.address);
        expect(externalToken.senderArr).to.have.members([sender.address.toString()]);
        expect(externalToken.tokenId.toNumber() ).to.equal(gameTokenId);
        
    })  


    checkExternalTokenProperties(
        gameTokenId=0,
        historyArr=[0],
        activeTokenIdsArr=[0]
    );

    
    
});



describe("Split", function () {
    let splitTokenId = 0;
    
    
    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        new_owners = [sender.address,addr1.address,
            addr2.address,addr3.address];
        new_owners_portion = [1 * 10 ** 11, 3 * 10 ** 11,
                              2 * 10 ** 11, 4 * 10 ** 11];
        let divisionTx = await quantum.splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
       
        for (let index in new_owners){  
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(quantum, 'OwnershipModified')
            .withArgs(sender.address, newOwner, firstGameTokenId,BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(quantum, 'Transfer')
            .withArgs(sender.address, AddressZero, splitTokenId);
        };
       
    })
    checkQuantumTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId=0,
        historyArr=[0,1,2,3,4],
        activeTokenIdsArr=[1,2,3,4]
    );


});




describe("Further split", function () {
    let splitTokenId = 1;
    

    
    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        new_owners = [sender.address,addr1.address]
        new_owners_portion = [5 * 10 ** 10,5 * 10 ** 10]
        let divisionTx = await quantum.splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
        for (let index in new_owners){  
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(quantum, 'OwnershipModified')
            .withArgs(sender.address, newOwner, firstGameTokenId,BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(quantum, 'Transfer')
            .withArgs(sender.address, AddressZero, splitTokenId);
        };
    
    })
    
    checkQuantumTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId=0,
        historyArr=[0,1,2,3,4,5,6],
        activeTokenIdsArr=[2,3,4,5,6]
    );

    
});


describe("Further split with different account", function () {
    let splitTokenId = 2;
    
    it("Should send percentage of a token to new owners", async function () {
        let sender = addr1;
        new_owners = [sender.address,addr2.address]
        new_owners_portion = [2 * 10 ** 11,1 * 10 ** 11]
        let divisionTx = await quantum.connect(sender).splitTokenOwnership(splitTokenId,new_owners,new_owners_portion);
        await divisionTx.wait()
        for (let index in new_owners){  
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(quantum, 'OwnershipModified')
            .withArgs(sender.address, newOwner, firstGameTokenId,BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(quantum, 'Transfer')
            .withArgs(sender.address, AddressZero, splitTokenId);
        };
        

    })
    checkQuantumTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId=0,
        historyArr=[0,1,2,3,4,5,6,7,8],
        activeTokenIdsArr=[3,4,5,6,7,8]
    );

    
    
});



describe("Return Token", function () {
    
    
    it("Should send and return the token", async function () {
        let sender = addr0;
        let externalTokenHash = quantum.makeExternalTokenHash(game.address,thirdGameTokenId)

        
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,thirdGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(quantum.address);
        let externalToken = await quantum.getExternalToken(externalTokenHash);
        let newTokenId = 9;
        let activeTokenIdsArr = [newTokenId];
        let historyArr = [newTokenId]; 
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);


        let returnTx = await quantum.connect(sender).returnToken(externalTokenHash);
        await expect(returnTx).to.emit(quantum, 'ExternalTokenReturn')
        .withArgs(game.address, sender.address, thirdGameTokenId);
        // Ensure old token has been burned
        await expect(returnTx).to.emit(quantum, 'Transfer')
        .withArgs(sender.address, AddressZero, newTokenId);
        
        activeTokenIdsArr = [];
        externalToken = await quantum.getExternalToken(externalTokenHash);
        expect(externalToken.activeTokenIdsArr).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);
    }),


    it("Should send and return the token the second time", async function () {
        let sender = addr0;
        let externalTokenHash = quantum.makeExternalTokenHash(game.address,thirdGameTokenId)

        
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,thirdGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(quantum.address);
        let externalToken = await quantum.getExternalToken(externalTokenHash);
        let newTokenId = 10;
        let activeTokenIdsArr = [newTokenId];
        let historyArr = [9,newTokenId]; 
        let senderArr = [
            sender.address.toString(),
            sender.address.toString()
        ];
        expect(externalToken.senderArr).to.have.members(senderArr);
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);


        let returnTx = await quantum.connect(sender).returnToken(externalTokenHash);
        await expect(returnTx).to.emit(quantum, 'ExternalTokenReturn')
        .withArgs(game.address, sender.address, thirdGameTokenId);
        // Ensure old token has been burned
        await expect(returnTx).to.emit(quantum, 'Transfer')
        .withArgs(sender.address, AddressZero, newTokenId);
        
        activeTokenIdsArr = [];
        externalToken = await quantum.getExternalToken(externalTokenHash);
        expect(externalToken.activeTokenIdsArr).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);
    
    })
});




describe("Illegal transactions", function () {
    

    it("Should ensure that only the owner may split token", async function () {
        let sender = addr1;
        new_owners = [sender.address];
        new_owners_portion = [1];
        await expect(quantum.connect(sender).splitTokenOwnership(0,new_owners,new_owners_portion))
        .to.be.revertedWith('Only the owner may split this token');
    }),

    it("Should ensure token can't be further split after it has been altered", async function () {
        let sender = addr0;
        let new_owners = [sender.address];
        let new_owners_portion = [1];
        await expect(quantum.connect(sender).splitTokenOwnership(0,new_owners,new_owners_portion))
        .to.be.revertedWith('Token may not  be altered more than once');
    }),


    it("Should ensure portion and address validity", async function () {
        let sender = addr0;
        let new_owners = [sender.address];
        let new_owners_portion = [1,2];
        await expect(quantum.connect(sender).splitTokenOwnership(5,new_owners,new_owners_portion))
        .to.be.revertedWith('The portion and address fields must be of equal length');


        new_owners = [sender.address,sender.address];
        new_owners_portion = [1];
        await expect(quantum.connect(sender).splitTokenOwnership(5,new_owners,new_owners_portion))
        .to.be.revertedWith('The portion and address fields must be of equal length');


        new_owners = [AddressZero];
        new_owners_portion = [1];
        await expect(quantum.connect(sender).splitTokenOwnership(5,new_owners,new_owners_portion))
        .to.be.revertedWith('Invalid recepient address included');


        new_owners = [addr2.address];
        new_owners_portion = [1];
        
        await expect(quantum.connect(sender).splitTokenOwnership(5,new_owners,new_owners_portion))
        .to.be.revertedWith('Incorrect portion allocation. They sum up to more or less than 100%');

        
    }),



    it("Should ensure that contract can only be paused \
        by user with MINTER_ROLE", async function () {
        let sender = addr1;
        let err_msg = `AccessControl: account ${addr1.address.toLowerCase()} is missing role ${MINTER_ROLE}`;

        await expect(quantum.connect(sender).pause())
        .to.be.revertedWith(err_msg);

    }),

    it("Should ensure initialization and split can't\
        be done when paused",async function(){
        let sender = addr0
        await quantum.connect(sender).pause();
        
        await expect(game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,secondGameTokenId))
        .to.be.revertedWith("Pausable: paused");

        await expect(quantum.connect(sender).splitTokenOwnership(5,new_owners,new_owners_portion))
        .to.be.revertedWith("Pausable: paused");
    }),

    it("Should ensure contract can be unpaused",async function(){
        let sender = addr0
        await quantum.connect(sender).unpause();
        let  initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,secondGameTokenId);
        await initTx.wait()
        
    }),


    it("Should ensure that only the owner can return token",async function(){
        let externalTokenHash = await quantum.makeExternalTokenHash(game.address,thirdGameTokenId);
        let sender = addr0;
        let  initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,thirdGameTokenId);
        await initTx.wait();

        
        await expect(quantum.connect(addr1).returnToken(externalTokenHash))
        .to.be.revertedWith("Only the owner may return this token");
        
    })


    it("Should ensure that the transferFrom and safeTransferFrom \
        functions are unavailable ",async function(){
       let sender = addr0;
    

        
        await expect(
            quantum["safeTransferFrom(address,address,uint256,bytes)"](sender.address,quantum.address,0,utils.formatBytes32String("random"))
        )
        .to.be.revertedWith("UnImplemented()");

        await expect(
            quantum["safeTransferFrom(address,address,uint256)"](sender.address,quantum.address,0)
        )
        .to.be.revertedWith("UnImplemented()");

        await expect(
            quantum.transferFrom(sender.address,quantum.address,0)
        )
        .to.be.revertedWith("UnImplemented()");
        
    })
    
    
    
    
});



function checkQuantumTokenProperties(splitTokenId) {

    it("Should ensure that the altered token\
        is no longer modifiable", async function () {
        
        let dividedToken = await quantum.TokenMap(splitTokenId); 
        expect(dividedToken.hasBeenAltered).to.equal(true);
        
    }),


    it("Should ensure that the split token\
        got to the intended beneficiaries", async function () {
        startTokenIndex = endTokenIndex;
        endTokenIndex = startTokenIndex + new_owners.length;
        for (i=startTokenIndex; i < endTokenIndex ;i++){
            let newOwner = new_owners[i-startTokenIndex];
            let newOwnerPortion = new_owners_portion[i-startTokenIndex];
            let newToken = await quantum.TokenMap(i);
            console.log(newToken)
            let externalTokenHash = await quantum.makeExternalTokenHash(game.address,firstGameTokenId);

            expect(newToken.owner).to.equal(newOwner)
            expect(newToken.portion).to.equal(newOwnerPortion);
            expect(newToken.hasBeenAltered).to.equal(false);
            expect(newToken.externalTokenHash).to.equal(externalTokenHash);
            expect(newToken.parentId.toNumber()).to.equal(splitTokenId);
         
        };
    })

}


function checkExternalTokenProperties(
        gameTokenId,
        historyArr,
        activeTokenIdsArr
        ){
    
    it("Should ensure that an ExternalToken\
        object has all the correct properties", async function () {
        let externalTokenHash = await quantum.makeExternalTokenHash(game.address,gameTokenId);
        let externalToken = await quantum.getExternalToken(externalTokenHash);

        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);

    }),

    it("Should ensure that the active token array sums up to 100%  ", async function () {
        let externalTokenHash = await quantum.makeExternalTokenHash(game.address,gameTokenId);
        checkSumTotal(externalTokenHash);
    })
}
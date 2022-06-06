
// incomplete tests for UserActiveTokenMap,History

const { expect } = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { AddressZero } = require("@ethersproject/constants");
const { utils } = require("ethers");
const { bigNumberToNumber, checkSumTotal } = require("./utils");
const { ethers } = require("hardhat");

let qubits;
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
const MAX_PORTION = 10 ** 12;
const MAX_INT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
const MINTER_ROLE = "0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a"
before(async function () {

    [addr0, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    let sender = addr0;
    const UtilsLibraryFactory = await ethers.getContractFactory("Utils");
    utilsLibrary = await UtilsLibraryFactory.deploy();

    const Qubits = await ethers.getContractFactory("Qubits", {
        libraries: {
          Utils: utilsLibrary.address,
        },
      });

    
    qubits = await Qubits.deploy();
    const Game = await ethers.getContractFactory("Game");
    game = await Game.deploy();
    await qubits.deployed();
    await game.deployed();
    console.log("Game ", game.address)
    console.log("Qubits ", qubits.address)

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
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, firstGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(firstGameTokenId)).to.equal(qubits.address);

    }),


        it("Should ensure that a Qubits token object is created \
        which will represent 100% ownership of the ExternalToken", async function () {
            const MAX_INT_BIGNUMBER = BigNumber.from(MAX_INT);
            let sender = addr0;
            let token = await qubits.TokenMap(0);

            let externalTokenHash = await qubits.makeExternalTokenHash(game.address, firstGameTokenId);
            expect(token.owner).to.equal(sender.address);
            expect(token.portion).to.equal(MAX_PORTION);
            expect(token.hasBeenAltered).to.equal(false);
            expect(token.externalTokenHash).to.equal(externalTokenHash);
            expect(token.parentId).to.equal(MAX_INT_BIGNUMBER);

            let userActiveTokenArr = [0];
            let userActiveTokensTx = await qubits.getUserActiveTokens(sender.address);
            expect(userActiveTokensTx.map(bigNumberToNumber))
                .to.have.members(userActiveTokenArr);


        }),

        it("Should ensure that basic ExternalToken data is accurate", async function () {
            let sender = addr0;
            let externalTokenHash = await qubits.makeExternalTokenHash(game.address, firstGameTokenId);
            let externalToken = await qubits.getExternalToken(externalTokenHash)

            expect(externalToken.contract_).to.equal(game.address);
            expect(externalToken.senderArr).to.have.members([sender.address.toString()]);
            expect(externalToken.tokenId.toNumber()).to.equal(gameTokenId);

        })


    checkExternalTokenProperties(
        gameTokenId = 0,
        historyArr = [0],
        activeTokenIdsArr = [0]
    );



});



describe("Split", function () {
    let splitTokenId = 0;


    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        new_owners = [sender.address, addr1.address,
        addr2.address, addr3.address];
        new_owners_portion = [1 * 10 ** 11, 3 * 10 ** 11,
        2 * 10 ** 11, 4 * 10 ** 11];
        let divisionTx = await qubits.splitTokenOwnership(splitTokenId, new_owners, new_owners_portion);
        await divisionTx.wait()

        for (let index in new_owners) {
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(qubits, 'OwnershipModified')
                .withArgs(sender.address, newOwner, firstGameTokenId, BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };

    })
    checkQubitsTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId = 0,
        historyArr = [0, 1, 2, 3, 4],
        activeTokenIdsArr = [1, 2, 3, 4]
    );


});




describe("Further split", function () {
    let splitTokenId = 1;



    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        new_owners = [sender.address, addr1.address]
        new_owners_portion = [5 * 10 ** 10, 5 * 10 ** 10]
        let divisionTx = await qubits.splitTokenOwnership(splitTokenId, new_owners, new_owners_portion);
        await divisionTx.wait()
        for (let index in new_owners) {
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(qubits, 'OwnershipModified')
                .withArgs(sender.address, newOwner, firstGameTokenId, BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };

    })

    checkQubitsTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId = 0,
        historyArr = [0, 1, 2, 3, 4, 5, 6],
        activeTokenIdsArr = [2, 3, 4, 5, 6]
    );


});


describe("Further split with different account", function () {
    let splitTokenId = 2;

    it("Should send percentage of a token to new owners", async function () {
        let sender = addr1;
        new_owners = [sender.address, addr2.address]
        new_owners_portion = [2 * 10 ** 11, 1 * 10 ** 11]
        let divisionTx = await qubits.connect(sender).splitTokenOwnership(splitTokenId, new_owners, new_owners_portion);
        await divisionTx.wait()
        for (let index in new_owners) {
            let newOwner = new_owners[index];
            let newOwnerPortion = new_owners_portion[index].toString();
            await expect(divisionTx).to.emit(qubits, 'OwnershipModified')
                .withArgs(sender.address, newOwner, firstGameTokenId, BigNumber.from(newOwnerPortion));
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };


    })
    checkQubitsTokenProperties(splitTokenId);
    checkExternalTokenProperties(
        gameTokenId = 0,
        historyArr = [0, 1, 2, 3, 4, 5, 6, 7, 8],
        activeTokenIdsArr = [3, 4, 5, 6, 7, 8]
    );



});



describe("Return Token", function () {


    it("Should send and return the token", async function () {
        let sender = addr0;
        let externalTokenHash = qubits.makeExternalTokenHash(game.address, thirdGameTokenId)


        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(qubits.address);
        let externalToken = await qubits.getExternalToken(externalTokenHash);
        let newTokenId = 9;
        let activeTokenIdsArr = [newTokenId];
        let historyArr = [newTokenId];
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);


        // split token
        let splitTx = await qubits.splitTokenOwnership(
            newTokenId,
            [sender.address,sender.address],
            [500000000000,500000000000]
        );
        await splitTx.wait();

        // split token again
        let splitTx2 = await qubits.splitTokenOwnership(
            11,
            [sender.address,sender.address],
            [250000000000,250000000000]
        );
        await splitTx2.wait();

        historyArr.push(10,11,12,13)


        let returnTx = await qubits.connect(sender).returnToken(externalTokenHash);
        await expect(returnTx).to.emit(qubits, 'ExternalTokenReturn')
            .withArgs(game.address, sender.address, thirdGameTokenId);
        

        activeTokenIdsArr = [];
        externalToken = await qubits.getExternalToken(externalTokenHash);
        expect(externalToken.activeTokenIdsArr).to.have.members(activeTokenIdsArr);
        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);
    }),


        it("Should send and return the token the second time", async function () {
            let sender = addr0;
            let externalTokenHash = qubits.makeExternalTokenHash(game.address, thirdGameTokenId)


            let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
            await safeTransferTx.wait();
            expect(await game.ownerOf(thirdGameTokenId)).to.equal(qubits.address);
            let externalToken = await qubits.getExternalToken(externalTokenHash);
            let newTokenId = 14;
            let activeTokenIdsArr = [newTokenId];
            let historyArr = [9,10,11,12,13, newTokenId];
            let senderArr = [
                sender.address.toString(),
                sender.address.toString()
            ];
            expect(externalToken.senderArr).to.have.members(senderArr);
            expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);
            expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);

            // split token
            let splitTx = await qubits.splitTokenOwnership(
                newTokenId,
                [sender.address,sender.address],
                [500000000000,500000000000]
            );
            await splitTx.wait();

            // split token again
            let splitTx2 = await qubits.splitTokenOwnership(
                16,
                [sender.address,sender.address],
                [250000000000,250000000000]
            );
            await splitTx2.wait();

            historyArr.push(15,16,17,18);

            let returnTx = await qubits.connect(sender).returnToken(externalTokenHash);
            await expect(returnTx).to.emit(qubits, 'ExternalTokenReturn')
                .withArgs(game.address, sender.address, thirdGameTokenId);
            // // Ensure old token has been burned
            // await expect(returnTx).to.emit(qubits, 'Transfer')
            //     .withArgs(sender.address, AddressZero, newTokenId);

            activeTokenIdsArr = [];
            externalToken = await qubits.getExternalToken(externalTokenHash);
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
        await expect(qubits.connect(sender).splitTokenOwnership(0, new_owners, new_owners_portion))
            .to.be.revertedWith('Only the owner may split this token');
    }),

        it("Should ensure token can't be further split after it has been altered", async function () {
            let sender = addr0;
            let new_owners = [sender.address];
            let new_owners_portion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(0, new_owners, new_owners_portion))
                .to.be.revertedWith('Token may not  be altered more than once');
        }),


        it("Should ensure portion and address validity", async function () {
            let sender = addr0;
            let new_owners = [sender.address];
            let new_owners_portion = [1, 2];
            await expect(qubits.connect(sender).splitTokenOwnership(5, new_owners, new_owners_portion))
                .to.be.revertedWith('The portion and address fields must be of equal length');


            new_owners = [sender.address, sender.address];
            new_owners_portion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(5, new_owners, new_owners_portion))
                .to.be.revertedWith('The portion and address fields must be of equal length');


            new_owners = [AddressZero];
            new_owners_portion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(5, new_owners, new_owners_portion))
                .to.be.revertedWith('Invalid recepient address included');


            new_owners = [addr2.address];
            new_owners_portion = [1];

            await expect(qubits.connect(sender).splitTokenOwnership(5, new_owners, new_owners_portion))
                .to.be.revertedWith('Incorrect portion allocation. They sum up to more or less than 100%');


        }),



        it("Should ensure that contract can only be paused \
        by user with MINTER_ROLE", async function () {
            let sender = addr1;
            let err_msg = `AccessControl: account ${addr1.address.toLowerCase()} is missing role ${MINTER_ROLE}`;

            await expect(qubits.connect(sender).pause())
                .to.be.revertedWith(err_msg);

        }),

        it("Should ensure initialization and split can't\
        be done when paused", async function () {
            let sender = addr0
            await qubits.connect(sender).pause();

            await expect(game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, secondGameTokenId))
                .to.be.revertedWith("Pausable: paused");

            await expect(qubits.connect(sender).splitTokenOwnership(5, new_owners, new_owners_portion))
                .to.be.revertedWith("Pausable: paused");
        }),

        it("Should ensure contract can be unpaused", async function () {
            let sender = addr0
            await qubits.connect(sender).unpause();
            let initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, secondGameTokenId);
            await initTx.wait()

        }),


        it("Should ensure that only the owner can return token", async function () {
            let externalTokenHash = await qubits.makeExternalTokenHash(game.address, thirdGameTokenId);
            let sender = addr0;
            let initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
            await initTx.wait();


            await expect(qubits.connect(addr1).returnToken(externalTokenHash))
                .to.be.revertedWith("Only the owner may return this token");

        })


    it("Should ensure that the transferFrom and safeTransferFrom \
        functions are unavailable ", async function () {
        let sender = addr0;



        await expect(
            qubits["safeTransferFrom(address,address,uint256,bytes)"](sender.address, qubits.address, 0, utils.formatBytes32String("random"))
        )
            .to.be.revertedWith("UnImplemented()");

        await expect(
            qubits["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, 0)
        )
            .to.be.revertedWith("UnImplemented()");

        await expect(
            qubits.transferFrom(sender.address, qubits.address, 0)
        )
            .to.be.revertedWith("UnImplemented()");

    })




});



function checkQubitsTokenProperties(splitTokenId) {

    it("Should ensure that the altered token\
        is no longer modifiable", async function () {

        let dividedToken = await qubits.TokenMap(splitTokenId);
        expect(dividedToken.hasBeenAltered).to.equal(true);

    }),


        it("Should ensure that the split token\
        got to the intended beneficiaries", async function () {
            startTokenIndex = endTokenIndex;
            endTokenIndex = startTokenIndex + new_owners.length;
            for (i = startTokenIndex; i < endTokenIndex; i++) {
                let newOwner = new_owners[i - startTokenIndex];
                let newOwnerPortion = new_owners_portion[i - startTokenIndex];
                let newToken = await qubits.TokenMap(i);
                console.log(newToken)
                let externalTokenHash = await qubits.makeExternalTokenHash(game.address, firstGameTokenId);

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
) {

    it("Should ensure that an ExternalToken\
        object has all the correct properties", async function () {
        let externalTokenHash = await qubits.makeExternalTokenHash(game.address, gameTokenId);
        let externalToken = await qubits.getExternalToken(externalTokenHash);

        expect(externalToken.historyArr.map(bigNumberToNumber)).to.have.members(historyArr);
        expect(externalToken.activeTokenIdsArr.map(bigNumberToNumber)).to.have.members(activeTokenIdsArr);

    }),

        it("Should ensure that the active token array sums up to 100%  ", async function () {
            let externalTokenHash = await qubits.makeExternalTokenHash(game.address, gameTokenId);
            checkSumTotal(externalTokenHash);
        })
}
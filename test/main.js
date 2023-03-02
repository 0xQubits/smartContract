
// incomplete tests for UserActiveTokenMap,History

const { expect } = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { AddressZero } = require("@ethersproject/constants");
const { utils } = require("ethers");
const { bigNumberToNumber, checkSumTotal,makeHash } = require("./utils");
const { ethers, upgrades } = require("hardhat");


let qubits;
let game;
let maliciousGame;
let addr0;
let addr1;
let addr2;
let addr3;
let addrs;
let firstGameTokenId;
let secondGameTokenId;
let thirdGameTokenId;
let newOwners;
let newOwnersPortion;
let startTokenIndex;
let endTokenIndex;
const MAX_PORTION = 10 ** 12;
const MAX_INT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
const PAUSER_ROLE = "0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a"
before(async function () {

    [addr0, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    let sender = addr0;
    const UtilsLibraryFactory = await ethers.getContractFactory("Utils");
    utilsLibrary = await UtilsLibraryFactory.deploy();


    const QubitsTokenRegistryFactory = await ethers.getContractFactory("QubitsTokenRegistry");
    const OtherTokenRegistryFactory = await ethers.getContractFactory("OtherTokenRegistry");
    const UserQubitsTokenRegistryFactory = await ethers.getContractFactory("UserQubitsTokenRegistry");


    qubitsTokenRegistry = await upgrades.deployProxy(QubitsTokenRegistryFactory);
    otherTokenRegistry = await upgrades.deployProxy(OtherTokenRegistryFactory);
    userQubitsTokenRegistry = await upgrades.deployProxy(UserQubitsTokenRegistryFactory);
    
    await qubitsTokenRegistry.deployed()
    await otherTokenRegistry.deployed()
    await userQubitsTokenRegistry.deployed()

    const QubitsFactory = await ethers.getContractFactory("Qubits");

    qubits = await upgrades.deployProxy(QubitsFactory,[
        qubitsTokenRegistry.address,
        otherTokenRegistry.address,
        userQubitsTokenRegistry.address
    ]);


    
    const Game = await ethers.getContractFactory("Game");
    game = await Game.deploy();

    const MaliciousGame = await ethers.getContractFactory("MaliciousGame");
    maliciousGame = await MaliciousGame.deploy();

    await qubits.deployed();
    await game.deployed();
    await maliciousGame.deployed();
    console.log("Game ", game.address)
    console.log("Qubits ", qubits.address)

    await qubitsTokenRegistry.setRegistryAdmin(
        qubits.address
    )
    await otherTokenRegistry.setRegistryAdmin(
        qubits.address
    )
    await userQubitsTokenRegistry.setRegistryAdmin(
        qubits.address
    )

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

    const mintMaliciousGameTx = await maliciousGame.awardItem(sender.address);
    await mintMaliciousGameTx.wait();
    expect(await maliciousGame.ownerOf(0)).to.equal(sender.address);

});





describe("Initialization", function () {


    it("Should that an external token can be sent to this contract", async function () {
        let sender = addr0;
        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, firstGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(firstGameTokenId)).to.equal(qubits.address);

    }),


        it("Should ensure that a Qubits token object is created \
        which will represent 100% ownership of the OtherToken", async function () {
            const MAX_INT_BIGNUMBER = BigNumber.from(MAX_INT);
            let sender = addr0;
            let token = await qubitsTokenRegistry.QubitsTokenMap(0);

            let externalTokenHash = makeHash(game.address, firstGameTokenId);
            expect(token.owner).to.equal(sender.address);
            expect(token.portion).to.equal(MAX_PORTION);
            expect(token.hasBeenAltered).to.equal(false);
            expect(token.externalTokenHash).to.equal(externalTokenHash);
            expect(token.parentId).to.equal(MAX_INT_BIGNUMBER);

            let userActiveTokenArr = [0];
            let userActiveTokensTx = await userQubitsTokenRegistry.get(sender.address);
            expect(userActiveTokensTx.map(bigNumberToNumber))
                .to.have.members(userActiveTokenArr);


        }),

        it("Should ensure that basic OtherToken data is accurate", async function () {
            let sender = addr0;
            let externalTokenHash = makeHash(game.address, firstGameTokenId);
            let externalToken = await otherTokenRegistry.get(externalTokenHash)

            expect(externalToken.contract_).to.equal(game.address);
            expect(externalToken.initializers).to.have.members([sender.address.toString()]);
            expect(externalToken.tokenId.toNumber()).to.equal(gameTokenId);

        })


    checkOtherTokenProperties(
        gameTokenId = 0,
        allQubitsTokens = [0],
        activeQubitsTokens = [0]
    );



});



describe("Split", function () {
    let splitTokenId = 0;


    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        newOwners = [sender.address, addr1.address,
        addr2.address, addr3.address];
        newOwnersPortion = [1 * 10 ** 11, 3 * 10 ** 11,
        2 * 10 ** 11, 4 * 10 ** 11];
        let divisionTx = await qubits.splitTokenOwnership(splitTokenId, newOwners, newOwnersPortion);
        await divisionTx.wait()

        for (let index in newOwners) {
            await expect(divisionTx).to.emit(otherTokenRegistry, 'OwnershipChanged')
            .withArgs(game.address,firstGameTokenId,splitTokenId + parseInt(index) + 1);
            
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };

    })
    checkQubitsTokenProperties(splitTokenId);
    checkOtherTokenProperties(
        gameTokenId = 0,
        allQubitsTokens = [0, 1, 2, 3, 4],
        activeQubitsTokens = [1, 2, 3, 4]
    );


});




describe("Further split", function () {
    let splitTokenId = 1;



    it("Should send percentage of a token to new owners", async function () {
        let sender = addr0;
        newOwners = [sender.address, addr1.address]
        newOwnersPortion = [5 * 10 ** 10, 5 * 10 ** 10]
        let divisionTx = await qubits.splitTokenOwnership(splitTokenId, newOwners, newOwnersPortion);
        await divisionTx.wait()
        for (let index in newOwners) {
            await expect(divisionTx).to.emit(otherTokenRegistry, 'OwnershipChanged')
            .withArgs(game.address,firstGameTokenId,splitTokenId + parseInt(index) + 4);// +4 minted tokens
            
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };

    })

    checkQubitsTokenProperties(splitTokenId);
    checkOtherTokenProperties(
        gameTokenId = 0,
        allQubitsTokens = [0, 1, 2, 3, 4, 5, 6],
        activeQubitsTokens = [2, 3, 4, 5, 6]
    );


});


describe("Further split with different account", function () {
    let splitTokenId = 2;

    it("Should send percentage of a token to new owners", async function () {
        let sender = addr1;
        newOwners = [sender.address, addr2.address]
        newOwnersPortion = [2 * 10 ** 11, 1 * 10 ** 11]
        let divisionTx = await qubits.connect(sender).splitTokenOwnership(splitTokenId, newOwners, newOwnersPortion);
        await divisionTx.wait()
        for (let index in newOwners) {
            await expect(divisionTx).to.emit(otherTokenRegistry, 'OwnershipChanged')
            .withArgs(game.address,firstGameTokenId,splitTokenId + parseInt(index) + 5);
            // Ensure token has been burned
            await expect(divisionTx).to.emit(qubits, 'Transfer')
                .withArgs(sender.address, AddressZero, splitTokenId);
        };


    })
    checkQubitsTokenProperties(splitTokenId);
    checkOtherTokenProperties(
        gameTokenId = 0,
        allQubitsTokens = [0, 1, 2, 3, 4, 5, 6, 7, 8],
        activeQubitsTokens = [3, 4, 5, 6, 7, 8]
    );



});



describe("Return Token", function () {


    it("Should send and return the token", async function () {
        let sender = addr0;
        let externalTokenHash = makeHash(game.address, thirdGameTokenId)


        let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
        await safeTransferTx.wait();
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(qubits.address);
        let externalToken = await otherTokenRegistry.get(externalTokenHash);
        let newTokenId = 9;
        let activeQubitsTokens = [newTokenId];
        let allQubitsTokens = [newTokenId];
        expect(externalToken.activeQubitsTokens.map(bigNumberToNumber)).to.have.members(activeQubitsTokens);
        expect(externalToken.allQubitsTokens.map(bigNumberToNumber)).to.have.members(allQubitsTokens);


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

        allQubitsTokens.push(10,11,12,13)


        let returnTx = await qubits.connect(sender).restoreTokenOwnership(externalTokenHash);
        
        await expect(returnTx).to.emit(otherTokenRegistry, 'Withdrawn')
            .withArgs(game.address,thirdGameTokenId);

        activeQubitsTokens = [];
        externalToken = await otherTokenRegistry.get(externalTokenHash);
        expect(externalToken.activeQubitsTokens).to.have.members(activeQubitsTokens);
        expect(externalToken.allQubitsTokens.map(bigNumberToNumber)).to.have.members(allQubitsTokens);
        expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);
    }),


        it("Should send and return the token the second time", async function () {
            let sender = addr0;
            let externalTokenHash = makeHash(game.address, thirdGameTokenId)


            let safeTransferTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
            await safeTransferTx.wait();
            expect(await game.ownerOf(thirdGameTokenId)).to.equal(qubits.address);
            let externalToken = await otherTokenRegistry.get(externalTokenHash);
            let newTokenId = 14;
            let activeQubitsTokens = [newTokenId];
            let allQubitsTokens = [9,10,11,12,13, newTokenId];
            let initializers = [
                sender.address.toString(),
                sender.address.toString()
            ];
            expect(externalToken.initializers).to.have.members(initializers);
            expect(externalToken.activeQubitsTokens.map(bigNumberToNumber)).to.have.members(activeQubitsTokens);
            expect(externalToken.allQubitsTokens.map(bigNumberToNumber)).to.have.members(allQubitsTokens);

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

            allQubitsTokens.push(15,16,17,18);

            let returnTx = await qubits.connect(sender).restoreTokenOwnership(externalTokenHash);

            await expect(returnTx).to.emit(otherTokenRegistry, 'Withdrawn')
            .withArgs(game.address,thirdGameTokenId);

            // // Ensure old token has been burned
            // await expect(returnTx).to.emit(qubits, 'Transfer')
            //     .withArgs(sender.address, AddressZero, newTokenId);

            activeQubitsTokens = [];
            externalToken = await otherTokenRegistry.get(externalTokenHash);
            expect(externalToken.activeQubitsTokens).to.have.members(activeQubitsTokens);
            expect(externalToken.allQubitsTokens.map(bigNumberToNumber)).to.have.members(allQubitsTokens);
            expect(await game.ownerOf(thirdGameTokenId)).to.equal(sender.address);

        })
});




describe("Illegal transactions", function () {


    it("Should ensure that only the owner may split token", async function () {
        let sender = addr1;
        newOwners = [sender.address];
        newOwnersPortion = [1];
        await expect(qubits.connect(sender).splitTokenOwnership(0, newOwners, newOwnersPortion))
            .to.be.revertedWith('Only the owner may call this function');
    }),

        it("Should ensure token can't be further split after it has been altered", async function () {
            let sender = addr0;
            let newOwners = [sender.address];
            let newOwnersPortion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(0, newOwners, newOwnersPortion))
                .to.be.revertedWith('Token may not be altered more than once');
        }),


        it("Should ensure portion and address validity", async function () {
            let sender = addr0;
            let newOwners = [sender.address];
            let newOwnersPortion = [1, 2];
            await expect(qubits.connect(sender).splitTokenOwnership(5, newOwners, newOwnersPortion))
                .to.be.revertedWith('The portion and address fields must be of equal length');


            newOwners = [sender.address, sender.address];
            newOwnersPortion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(5, newOwners, newOwnersPortion))
                .to.be.revertedWith('The portion and address fields must be of equal length');


            newOwners = [AddressZero];
            newOwnersPortion = [1];
            await expect(qubits.connect(sender).splitTokenOwnership(5, newOwners, newOwnersPortion))
                .to.be.revertedWith('Invalid recepient address included');


            newOwners = [addr2.address];
            newOwnersPortion = [1];

            await expect(qubits.connect(sender).splitTokenOwnership(5, newOwners, newOwnersPortion))
                .to.be.revertedWith('Incorrect portion sum');


        }),



        it("Should ensure that contract can only be paused \
        by user with PAUSER_ROLE", async function () {
            let sender = addr1;
            let err_msg = `AccessControl: account ${addr1.address.toLowerCase()} is missing role ${PAUSER_ROLE}`;

            await expect(qubits.connect(sender).pause())
                .to.be.revertedWith(err_msg);

        }),

        it("Should ensure initialization and split can't\
        be done when paused", async function () {
            let sender = addr0
            await qubits.connect(sender).pause();

            await expect(game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, secondGameTokenId))
                .to.be.revertedWith("Pausable: paused");

            await expect(qubits.connect(sender).splitTokenOwnership(5, newOwners, newOwnersPortion))
                .to.be.revertedWith("Pausable: paused");
        }),

        it("Should ensure contract can be unpaused", async function () {
            let sender = addr0
            await qubits.connect(sender).unpause();
            let initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, secondGameTokenId);
            await initTx.wait()

        }),


        it("Should ensure that only the owner can return token", async function () {
            let externalTokenHash = makeHash(game.address, thirdGameTokenId);
            let sender = addr0;
            let initTx = await game["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, thirdGameTokenId);
            await initTx.wait();


            await expect(qubits.connect(addr1).restoreTokenOwnership(externalTokenHash))
                .to.be.revertedWith("Only the owner may call this function");

        })


    it("Should ensure that the transferFrom and safeTransferFrom \
        functions are unavailable ", async function () {
        let sender = addr0;



        await expect(
            qubits["safeTransferFrom(address,address,uint256,bytes)"](sender.address, qubits.address, 0, utils.formatBytes32String("random"))
        )
            .to.be.revertedWith("Disabled()");

        await expect(
            qubits["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, 0)
        )
            .to.be.revertedWith("Disabled()");

        await expect(
            qubits.transferFrom(sender.address, qubits.address, 0)
        )
            .to.be.revertedWith("Disabled()");

    })

    it("should ensure onERC721Received calls from a non ERC721 address to be reverted", async function () {
        let sender = addr0;
        await expect(
            qubits["onERC721Received(address,address,uint256,bytes)"](sender.address, qubits.address, 0, utils.formatBytes32String("random"))
        )
        .to.be.reverted;
    })

    it("should ensure onERC721Received calls from a malicious ERC721 contract to be reverted", async function () {
        let sender = addr0;

        await expect(
            maliciousGame["safeTransferFrom(address,address,uint256)"](sender.address, qubits.address, 0)
        )
            .to.be.revertedWith("Token not received");
    })
 




});



function checkQubitsTokenProperties(splitTokenId) {

    it("Should ensure that the altered token\
        is no longer modifiable", async function () {

        let dividedToken = await qubitsTokenRegistry.QubitsTokenMap(splitTokenId);
        expect(dividedToken.hasBeenAltered).to.equal(true);

    }),


        it("Should ensure that the split token\
        got to the intended beneficiaries", async function () {
            startTokenIndex = endTokenIndex;
            endTokenIndex = startTokenIndex + newOwners.length;
            for (i = startTokenIndex; i < endTokenIndex; i++) {
                let newOwner = newOwners[i - startTokenIndex];
                let newOwnerPortion = newOwnersPortion[i - startTokenIndex];
                let newToken = await qubitsTokenRegistry.QubitsTokenMap(i);
                console.log(newToken)
                let externalTokenHash = makeHash(game.address, firstGameTokenId);

                expect(newToken.owner).to.equal(newOwner)
                expect(newToken.portion).to.equal(newOwnerPortion);
                expect(newToken.hasBeenAltered).to.equal(false);
                expect(newToken.externalTokenHash).to.equal(externalTokenHash);
                expect(newToken.parentId.toNumber()).to.equal(splitTokenId);

            };
        })

}


function checkOtherTokenProperties(
    gameTokenId,
    allQubitsTokens,
    activeQubitsTokens
) {

    it("Should ensure that an OtherToken\
        object has all the correct properties", async function () {
        let externalTokenHash = makeHash(game.address, gameTokenId);
        let externalToken = await otherTokenRegistry.get(externalTokenHash);

        expect(externalToken.allQubitsTokens.map(bigNumberToNumber)).to.have.members(allQubitsTokens);
        expect(externalToken.activeQubitsTokens.map(bigNumberToNumber)).to.have.members(activeQubitsTokens);

    }),

        it("Should ensure that the active token array sums up to 100%  ", async function () {
            let externalTokenHash = makeHash(game.address, gameTokenId);
            checkSumTotal(externalTokenHash);
        })
}
const { expect } = require("chai");
const { utils } = require("ethers");


function bigNumberToNumber(bigNumber) {
    return bigNumber.toNumber();
}

function addressToString(address) {
    return address.address;
}

function makeHash(address,tokenId) {
    let encodedHash = utils.solidityPack(
        ["address", "uint"],
        [address, tokenId]
    );
    return utils.keccak256(encodedHash);
}

async function checkSumTotal(externalTokenHash) {
    let activeTokens = await qubits.getActiveTokenArr(externalTokenHash);
    let total = 0;
    for (token of activeTokens) {
        total += token.portion.toNumber();
    };
    expect(total).to.equal(MAX_PORTION);
}


module.exports = {
    bigNumberToNumber: bigNumberToNumber,
    addressToString: addressToString,
    checkSumTotal: checkSumTotal,
    makeHash:makeHash
}
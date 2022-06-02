const { expect } = require("chai");

function bigNumberToNumber(bigNumber){
    return bigNumber.toNumber();
}

function addressToString(address){
    return address.address;
}

async function checkSumTotal(externalTokenHash){
    let activeTokens = await qubits.getActiveTokenArr(externalTokenHash);
    let total = 0;
    for (token of activeTokens){
        total+=token.portion.toNumber();
    };
    expect(total).to.equal(MAX_PORTION);
}


module.exports = {
    bigNumberToNumber:bigNumberToNumber,
    addressToString:addressToString,
    checkSumTotal:checkSumTotal
}
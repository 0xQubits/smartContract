const { expect } = require("chai");

function bigNumberToNumber(bigNumber){
    return bigNumber.toNumber();
}

async function checkSumTotal(externalTokenHash){
    let activeTokens = await bitToken.getActiveTokenArr(externalTokenHash);
    let total = 0;
    for (token of activeTokens){
        total+=token.portion.toNumber();
    };
    expect(total).to.equal(MAX_PORTION);
}


module.exports = {
    bigNumberToNumber:bigNumberToNumber,
    checkSumTotal:checkSumTotal
}
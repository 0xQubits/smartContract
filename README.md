## Qubits [Smart Contracts] https://0xqubits.com

This repository contains a collection of smart contract contracts that can be used to spit up ownership of Non fungible tokens(NFTs). <br>
For example, you might own an nft for a song or a painting and you want to split the ownership between you and somebody else. <br>
 <br>
In order to do that, you can just send your token to Qubits smart contract and once we have ownership of your tokens, you can call  <br>
the `splitTokenOwnership` function of the smart contract to split the ownership between yourself and other parties and that's it.  <br>
 <br> 
If any third party subsequently wants to verify who owns what token, they can just go to the qubits app and enter the original nft's smart <br> contract address and we reveal the current token owners, what portion they have and how it got passed down to them. <br>
 <br> 
You can interact with the smart contracts at https://0xqubits.com
 <br> 

### SETUP:
- create a file named `env` following the env.example file in this directory <br>
- source env: $ `source source.sh` <br>
- package installation: $ `npm install` <br>
- test: $`npx hardhat test`<br>
- deployment: $`npx hardhat run scripts/deploy.js --network <network>`<br>
`note:` available networks can be found in `hardhat.config.js`<br>


### TODO: 
- update deployment scripts
- rewrite and reorganize tests using Foundry 

Say hi @ https://twitter.com/0xCredence <br>
           mailto: lojetokun@gmail.com

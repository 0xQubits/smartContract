// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../common/Variables.sol";
import "hardhat/console.sol";

 

/**
 * @dev A smart contract for storing details about nfts received by qubits smart contract
 * for the purpose of splitting ownership of the said token
 */
contract OtherTokenRegistry is AccessControlUpgradeable,UUPSUpgradeable{

    mapping(bytes32 => Variables.ReceivedToken) public ReceivedTokenMap;
    event OwnershipChanged(
        address contract_,
        uint256 contractTokenId,
        uint256 mintedQubitsTokenId
    );

    /** Event emitted after a token is deposited to qubits smart contract */
    event Deposit(
        address contract_,
        uint256 contractTokenId
    );

    /** Event emitted after a token is withdrawn from qubits smart contract */
    event Withdrawn(
        address contract_,
        uint256 contractTokenId
    );



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(Variables.UPGRADER_ROLE)
    {}


    /**
    * @dev Get a received token object using a hash
    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function    */
    function get(bytes32 keyHash) public view returns (Variables.ReceivedToken memory) {
        return ReceivedTokenMap[keyHash];
    }


    /**
    * @dev Steps to be taken to update the received
    * token object after a qubits token has been minted

    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function
    * @param sender - the sender of the the nft to qubits contract
    * @param _contract - the external nft's contract address
    * @param _receivedTokenId - the external nft's token id
    * @param _qubitsTokenId - the qubits token minted in relation to the nft used to signify the percentage of ownernship of the external nft
    */
    function handleTokenMint(
        bytes32 keyHash,
        address sender,
        address _contract,
        uint256 _receivedTokenId,
        uint256 _qubitsTokenId
    ) public {
        _addReceivedToken(keyHash, sender, _contract, _receivedTokenId, _qubitsTokenId);
        _updateHistory(keyHash, _qubitsTokenId);
        emit Deposit(_contract, _receivedTokenId);
    }
    



    /** 
     * @dev This operation is only called when an external nft's ownership 
     * is being split. Since the old qubits token is burned whenever ownership is split,
     *  we need to remove the burned qubits token from the active tokens array and add
     * the newly minted qubits token to the list of active tokens

     * @param keyHash - the hash for getting the token object.
     * The hash is gotten using the Utils.makeHash function
     * @param burnedQubitsToken- the qubits token id being burned
     * @param mintedQubitsTokens- the newly minted qubits token ids
     */
    function handleTokenSplit(
        bytes32 keyHash,
        uint256 burnedQubitsToken,
        uint256[] memory mintedQubitsTokens

    ) public {
        // @security check perms


        assert(mintedQubitsTokens.length > 0);
        uint256[] storage activeTokenIds = ReceivedTokenMap[keyHash].activeTokenIdsArr;
        for (uint256 i = 0; i < activeTokenIds.length; i++) {
            uint256 tokenId = activeTokenIds[i];
            if (tokenId == burnedQubitsToken) {
                // replace burned token with first minted token in place
                activeTokenIds[i] = mintedQubitsTokens[0];
                _updateHistory(keyHash, mintedQubitsTokens[0]);

                // we check if the length is greater than one
                // because the first element has been added in place 
                if (mintedQubitsTokens.length > 1) {
                    for (uint256 j = 1; j < mintedQubitsTokens.length; j++) {
                        activeTokenIds.push(mintedQubitsTokens[j]);
                        _updateHistory(keyHash, mintedQubitsTokens[j]);
                    }
                    break;
                }
            }
        }
    }



    /**
    * @dev Steps to be taken after a token's ownership
    * has been taken away from qubits smart contract by 
    * a person or entity who has 100% ownership of the token
    * @param keyHash hash to find received token object.The hash is gotten using the Utils.makeHash function
    */
    function handleTokenExit(bytes32 keyHash) public {
        // clear active tokens array
        Variables.ReceivedToken storage rToken  = ReceivedTokenMap[keyHash];
        uint256[] storage activeTokenIdsArr = rToken.activeTokenIdsArr;
        uint256 len = activeTokenIdsArr.length;
        for (uint256 i = 0; i < len; i++) {
            activeTokenIdsArr.pop();
        }
        assert(activeTokenIdsArr.length == 0);

        // show that token is no longer 
        // owned by qubits smart contract
        rToken.isWithUs = false;
        emit Withdrawn(rToken.contract_, rToken.tokenId);
    }



    /**
    * @dev Steps to be taken when a qubits receives an nft

    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function
    * @param sender - the sender of the the external nft to qubits contract
    * @param _contract - the external nft's contract address
    * @param _receivedTokenId - the external nft's token id
    * @param _qubitsTokenId - the qubits token minted in relation to the nft used to signify the percentage of ownernship of the external nft
    */
    function _addReceivedToken(
        bytes32 keyHash,
        address sender,
        address _contract,
        uint256 _receivedTokenId,
        uint256 _qubitsTokenId
    ) public {
        Variables.ReceivedToken storage rToken = ReceivedTokenMap[keyHash];
        // make sure we don't overwrite 
        // just incase there is a hash collision
        if (rToken.contract_ == address(0)){
            rToken.contract_ = _contract;
            rToken.tokenId = _receivedTokenId;
        }

        // set the active token array if 
        // token is just being initialized
        assert(rToken.isWithUs == false);
        assert(rToken.activeTokenIdsArr.length == 0);
        rToken.activeTokenIdsArr = [_qubitsTokenId];
        rToken.isWithUs = true;
        
        // update sender array
        rToken.senderArr.push(sender);

        // update object in mapping
        ReceivedTokenMap[keyHash] = rToken;
    }



    function _updateHistory(
        bytes32 keyHash,
        uint256 _qubitsTokenId
    ) private {
        // update operation 
        Variables.ReceivedToken storage rToken = ReceivedTokenMap[keyHash];
        assert(rToken.isWithUs == true);

        // update history
        rToken.historyArr.push(_qubitsTokenId);
        emit OwnershipChanged(rToken.contract_,rToken.tokenId,_qubitsTokenId);

    }

}

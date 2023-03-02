// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "../common/library/Variables.sol";
import "../common/library/Utils.sol";
import "../common/abstract/Registry.sol";

 

/**
 * @title OtherTokenRegistry 
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 * @dev A smart contract for storing details about nfts received by qubits smart contract
 * for the purpose of splitting ownership of the said token
 */
contract OtherTokenRegistry is Registry {

    mapping(bytes32 => Variables.OtherToken) public OtherTokenMap;

    /** Event emitted after the ownership structure of an nft has updated */
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

    function initialize() public initializer {
        __Registry_init();
    }

    /**
    * @dev Get a received token object using a hash
    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function    */
    function get(bytes32 keyHash) public view returns (Variables.OtherToken memory) {
        return OtherTokenMap[keyHash];
    }

    /**
    * @dev Check if a token is initialized
    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function   
    */
    function isInitialized(bytes32 keyHash) public view returns (bool) {
        return OtherTokenMap[keyHash].initialized;
    }

    /**
    * @dev Check if a token is initialized
    * @param otherToken - the token 
    */
    function isInitialized(Variables.OtherToken memory otherToken) public pure returns (bool) {
        return otherToken.initialized;
    }

    /**
    * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
    *
    * @dev Steps to be taken to update the received
    * token object after an nft is sent to qubits

    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function
    * @param sender - the sender of the the nft to qubits contract
    * @param _contract - the external nft's contract address
    * @param _receivedTokenId - the external nft's token id
    * @param _qubitsTokenId - the first qubits token minted in relation to the nft used to signify 100% ownernship of the external nft
    */
    function handleTokenInitialization(
        bytes32 keyHash,
        address sender,
        address _contract,
        uint256 _receivedTokenId,
        uint256 _qubitsTokenId
    ) external onlyRole(Variables.REGISTRY_ADMIN_ROLE) {
        _handleTokenInitialization(keyHash, sender, _contract, _receivedTokenId, _qubitsTokenId);

        emit Deposit(_contract, _receivedTokenId);
    }
    


    /**
     * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
     *
     * @dev This operation is only called when an external nft's ownership 
     * is being split. Since the old qubits token is burned whenever ownership is split,
     *  we need to remove the burned qubits token from the active tokens array and add
     * the newly minted qubits token to the list of active tokens

     * @param keyHash - the hash for getting the token object.
     * The hash is gotten using the Utils.makeHash function
     * @param burnedQubitsToken- the qubits token id being burned
     * @param mintedQubitsTokens[]- the newly minted qubits token ids
     */
    function handleTokenSplit(
        bytes32 keyHash,
        uint256 burnedQubitsToken,
        uint256[] memory mintedQubitsTokens

    ) external onlyRole(Variables.REGISTRY_ADMIN_ROLE) {

        assert(mintedQubitsTokens.length > 0);
        uint256[] storage activeTokenIds = OtherTokenMap[keyHash].activeQubitsTokens;
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
    * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
    *
    * @dev Steps to be taken after a token's ownership
    * has been taken away from qubits smart contract by 
    * a person or entity who has 100% ownership of the token
    * @param keyHash hash to find received token object.The hash is gotten using the Utils.makeHash function
    */
    function handleTokenExit(
        bytes32 keyHash
        ) external onlyRole(Variables.REGISTRY_ADMIN_ROLE){
        // clear active tokens array
        Variables.OtherToken storage otherToken  = OtherTokenMap[keyHash];
        uint256[] storage activeQubitsTokens = otherToken.activeQubitsTokens;
        uint256 len = activeQubitsTokens.length;
        for (uint256 i = 0; i < len; i++) {
            activeQubitsTokens.pop();
        }
        assert(Utils.isEmpty(activeQubitsTokens));

        // set initialized to false
        _setInitialized(keyHash, false);
        emit Withdrawn(otherToken.contract_, otherToken.tokenId);
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
    function _handleTokenInitialization(
        bytes32 keyHash,
        address sender,
        address _contract,
        uint256 _receivedTokenId,
        uint256 _qubitsTokenId
    ) private {
        Variables.OtherToken storage otherToken = OtherTokenMap[keyHash];
        // make sure we don't overwrite 
        // just incase there is a hash collision
        if (otherToken.contract_ == address(0)){
            otherToken.contract_ = _contract;
            otherToken.tokenId = _receivedTokenId;
        }

        // set the active token array
        assert(Utils.isEmpty(otherToken.activeQubitsTokens));
        otherToken.activeQubitsTokens = [_qubitsTokenId];

        // update initializers array
        otherToken.initializers.push(sender);  

        // update object in mapping
        OtherTokenMap[keyHash] = otherToken;

        // set initialized
        _setInitialized(keyHash, true);

        // update history
        _updateHistory(keyHash, _qubitsTokenId);



    }


    /**
    * @dev Set nft initilization
    *
    * @param keyHash - the hash for getting the token object.
    * The hash is gotten using the Utils.makeHash function
    * @param value - true if token is with us else false
    */
    function _setInitialized(bytes32 keyHash, bool value) private {
        Variables.OtherToken storage otherToken = OtherTokenMap[keyHash];
        assert(otherToken.initialized != value);
        otherToken.initialized = value;
    }



    function _updateHistory(
        bytes32 keyHash,
        uint256 _qubitsTokenId
    ) private {
        // update operation 
        Variables.OtherToken storage otherToken = OtherTokenMap[keyHash];
        assert(isInitialized(otherToken));

        // update history
        otherToken.allQubitsTokens.push(_qubitsTokenId);
        emit OwnershipChanged(otherToken.contract_,otherToken.tokenId,_qubitsTokenId);

    }

}

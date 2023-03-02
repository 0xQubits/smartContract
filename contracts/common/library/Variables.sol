// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

/**
 * @title Variables - library for storing common variables
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 */
library Variables{
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    uint256 internal constant MAX_INT = uint256(2**256 - 1);
    
    /** Denotes 100% ownership of an nft */ 
    uint256 public constant FULL_OWNERSHIP_VALUE = uint256(10)**uint256(12);

    /**
     * @dev Object representing details about an nft received by qubits
     */
    struct OtherToken {

        /** Nft's id */
        uint256 tokenId;


        /** the nft's contract address */
        address contract_;


        /** Whether or not token is still owned
         *  by qubits smart contract 
         */
        bool initialized;


        /** Array of people who have sent the token 
         * to the smart contract. It will usually be an array 
         * containing one address but it may be more if 
         * the token has been sent to qubits more than once  
         */

        address[] initializers;

                
        /** Qubits token Ids of all current owners */
        uint256[] activeQubitsTokens;


        /** All qubits tokens that have ever been used to
         * represent a percentage of ownership of the nft
         */
        uint256[] allQubitsTokens;


    }

    /**
     * @dev Object representing details about a qubits token
     */
    struct QubitsToken {

        /** the qubits token id */
        uint256 id;

        /** address of token owner */
        address owner;


        /** portion of token ownership
         * represented as a portion of 
         * FULL_OWNERSHIP_VALUE 
         */
        uint256 portion;


        /**
         * Whether or not this token has been split
         * or altered in any way.
         */
        bool hasBeenAltered;


        /** 
         * The hash of the received nft and contract address
         * see Utils.makeHash
         */
        bytes32 externalTokenHash;


        /** qubits token id that was split in order for
         * the current token id to be created. 
         *
         * It may be Variables.MAX_INT if the token has no parent
         */
        uint256 parentId;


    }

}
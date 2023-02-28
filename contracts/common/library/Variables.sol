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
    uint256 public constant FULL_OWNERSHIP_VALUE = uint256(10)**uint256(12); // 10 ^ 12
    


    struct ReceivedToken {
        // Stores information on the
        // received External Token
        address[] senderArr;
        address contract_;
        uint256 tokenId;
        uint256[] historyArr;
        // Qubits token Ids of all current owners
        uint256[] activeTokenIdsArr;
        /** Whether or not token is still in our possession */
        bool isWithUs;
    }

    struct QubitsToken {
        // Stores Qubits token information
        uint256 id;
        address owner;
        uint256 portion;
        bool hasBeenAltered;
        bytes32 externalTokenHash;
        uint256 parentId;
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


library Variables{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

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
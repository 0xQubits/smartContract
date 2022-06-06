// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct ExternalToken {
    // Stores information on the
    // received External Token
    address[] senderArr;
    address contract_;
    uint256 tokenId;
    uint256[] historyArr;
    // Qubits token Ids of all current owners
    uint256[] activeTokenIdsArr;
}

struct InternalToken {
    // Stores Qubits token information
    uint256 id;
    address owner;
    uint256 portion;
    bool hasBeenAltered;
    bytes32 externalTokenHash;
    uint256 parentId;
}


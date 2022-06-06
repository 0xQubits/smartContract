// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Utils {
    function makeHash(uint256 _tokenId)
        public
        view
        returns (bytes32)
    {
        // constructs hash from external contract address and token id
        return keccak256(abi.encodePacked(msg.sender, _tokenId));
    }
}

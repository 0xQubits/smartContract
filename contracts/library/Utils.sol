// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Utils {
    function makeHash(address contract_, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(contract_, _tokenId));
    }
}

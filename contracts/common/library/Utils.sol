// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;
/**
 * @title Utils - library for storing common utility functions
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 */
library Utils {
    /** 
     * @dev use nft contract address and a token id to make 
     * a hash that can be used to identify an nft uniquely 
     */
    function makeHash(address _contract, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_contract, _tokenId));
    }

    function isEmpty(uint[] memory array) internal pure returns (bool){
        return (array.length == 0);
    }
}

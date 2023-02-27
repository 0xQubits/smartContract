// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../common/Variables.sol";
 
/**
 * @dev A smart contract for storing details about qubits tokens connected to each user.
 * This information is stored here to make lookups faster
 */
contract UserQubitsTokenRegistry is AccessControlUpgradeable,UUPSUpgradeable {

    mapping(address => uint256[]) public UserActiveTokenMap;

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
     * @dev Get a user's active tokens
     * @param _address the address of the user
     */
    function get(address _address) public view returns (uint256[] memory) {
        return UserActiveTokenMap[_address];
    }

    /**
     * @dev This function adds a specified token ID to the list of active tokens for a user. 
     * @param to the address of the user whose active token list needs to be updated
     * @param tokenId the ID of the token to remove from the user's active token list
     */
    function add(address to, uint256 tokenId) public {
        uint256[] storage userActiveTokens = UserActiveTokenMap[to];
        userActiveTokens.push(tokenId);
    }

    /**
     * @dev This function removes the specified token ID from the list of active tokens for a user. 
     * @param from the address of the user whose active token list needs to be updated
     * @param tokenId the ID of the token to remove from the user's active token list
     */
    function remove( address from, uint256 tokenId) public {
        uint256[] storage userActiveTokens = UserActiveTokenMap[from];
        for (uint256 i = 0; i < userActiveTokens.length; i++) {
            if (userActiveTokens[i] == tokenId) {
                userActiveTokens[i] = userActiveTokens[userActiveTokens.length - 1];
                userActiveTokens.pop();
                break;
            }
        }
    }



}
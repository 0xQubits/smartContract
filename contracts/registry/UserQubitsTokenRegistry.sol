// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "../common/abstract/Registry.sol";
import "../common/library/Variables.sol";
 
/**
 * @title UserQubitsTokenRegistry
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 * @dev A smart contract for storing details about qubits tokens connected to each user.
 * This information is stored here to make lookups faster
 */
contract UserQubitsTokenRegistry is Registry {

    mapping(address => uint256[]) public UserActiveTokenMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Registry_init();
    }

    /**
     * @dev Get a user's active tokens
     * @param _address the address of the user
     */
    function get(address _address) public view returns (uint256[] memory) {
        return UserActiveTokenMap[_address];
    }

    /** 
     * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
     *
     * @dev This function adds a specified token ID to the list of active tokens for a user. 
     * @param to the address of the user whose active token list needs to be updated
     * @param tokenId the ID of the token to remove from the user's active token list
     */
    function add(address to, uint256 tokenId) external onlyRole(Variables.REGISTRY_ADMIN_ROLE) {
        uint256[] storage userActiveTokens = UserActiveTokenMap[to];
        userActiveTokens.push(tokenId);
    }

    /**
     * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
     *
     * @dev This function removes the specified token ID from the list of active tokens for a user. 
     * @param from the address of the user whose active token list needs to be updated
     * @param tokenId the ID of the token to remove from the user's active token list
     */
    function remove( address from, uint256 tokenId) external onlyRole(Variables.REGISTRY_ADMIN_ROLE){
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
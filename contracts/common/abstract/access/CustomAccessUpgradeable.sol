// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../../common/library/Variables.sol";

 

/**
 * @title CustomAccessUpgradeable - Common contract for managing access and upgrade pattern
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 */
abstract contract CustomAccessUpgradeable is AccessControlUpgradeable,PausableUpgradeable,UUPSUpgradeable{
   
    /**
     * @dev Initializes the contract 
     */
    function __CustomAccessUpgradeable_init() internal onlyInitializing {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Variables.PAUSER_ROLE, msg.sender);
        _grantRole(Variables.UPGRADER_ROLE, msg.sender);
     }

    function _authorizeUpgrade(address newImplementation)
        internal 
        override
        onlyRole(Variables.UPGRADER_ROLE)
    {}


    function pause() external onlyRole(Variables.PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(Variables.PAUSER_ROLE) {
        _unpause();
    }


}

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../common/library/Variables.sol";
import "../../common/abstract/access/CustomAccessUpgradeable.sol";

 

/** 
 * @title Registry - Abstract registry contract
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 */
abstract contract Registry is CustomAccessUpgradeable{

    /**
     * @dev Initializes the contract 
     */
    function __Registry_init() internal onlyInitializing {
        __CustomAccessUpgradeable_init();
    }

    /**
     * @dev Set the smart contract address that can call
     * restricted or sensitive registry functions. The admin
     * smart contract should be the deployed address of Qubits.sol
     *
     * It is to be called manually after deploying 
     * the registry contract as well as Qubits.sol

     * @param _address the smart contract address
     */
    function setRegistryAdmin(address _address)
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            AddressUpgradeable.isContract(_address),
            "The address must belong to a smart contract"
        );
        _grantRole(Variables.REGISTRY_ADMIN_ROLE, _address);
    }



}

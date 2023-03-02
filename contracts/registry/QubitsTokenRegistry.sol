// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "../common/library/Variables.sol";
import "../common/abstract/Registry.sol";

 
/**
 * @title QubitsTokenRegistry
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 * @dev A smart contract for storing details about internal qubits tokens
 */
contract QubitsTokenRegistry is Registry {
 
    mapping(uint256 => Variables.QubitsToken) public QubitsTokenMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Registry_init();
    }
    
    /** 
     * @dev Get the qubits token object
     *  after specifying the token id 
     */
    function get(uint256 _tokenId) public view returns (Variables.QubitsToken memory) {
        return QubitsTokenMap[_tokenId];
    }

    /**
     * @dev Gets an array of Qubits token objects
     * when given an array of token ids
     */
    function getMany(uint256[] memory _tokenIds)
        public
        view
        returns (Variables.QubitsToken[] memory)
    {
        Variables.QubitsToken[] memory qubitsTokens = new Variables.QubitsToken[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            qubitsTokens[i] = QubitsTokenMap[_tokenIds[i]];
        }
        return qubitsTokens;
    }

    /**     
     * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
     *
     * @dev Create a token object after a token has been minted and
     * add it to the mapping of token ids to token objects
     */
    function create(
        uint256 _tokenId,
        address _to,
        uint256 _portion,
        bytes32 _hash,
        uint256 _parentId
    ) external onlyRole(Variables.REGISTRY_ADMIN_ROLE){
        Variables.QubitsToken memory qubitsToken;
        qubitsToken.id = _tokenId;
        qubitsToken.owner = _to;
        qubitsToken.portion = _portion;
        qubitsToken.hasBeenAltered = false;
        qubitsToken.externalTokenHash = _hash;
        qubitsToken.parentId = _parentId;
        QubitsTokenMap[_tokenId] = qubitsToken;
    }

    /**
     * @dev PROTECTED - onlyRole Variables.REGISTRY_ADMIN_ROLE
     *
     * @dev Set the hasBeenAltered property of a token 
     * object to true so that it can not be reassigned
     */
    function invalidate(
        uint256 _tokenId
    ) external onlyRole(Variables.REGISTRY_ADMIN_ROLE) {
        Variables.QubitsToken storage qubitsToken = QubitsTokenMap[_tokenId];
        qubitsToken.hasBeenAltered = true;
    }


    /**
     * @dev Check user and token permissions 
     * before a token is transferred/split
     */
    function checkTransferPermission(
        uint256 _tokenId,
        address _owner
    ) public view {
        Variables.QubitsToken memory qubitsToken = QubitsTokenMap[_tokenId];
        assert(qubitsToken.owner != address(0));
        require(
            qubitsToken.owner == _owner,
            "Only the owner may call this function"
        );
        require(
            qubitsToken.hasBeenAltered == false,
            "Token may not be altered more than once"
        );
    }

    /**
     * @dev Ensure that all the parameters set by a user
     * is valid before trying to initiate a transfer
     */
    function validateTransferParameters(
        uint256 _tokenId,
        address[] memory newOwners,
        uint[] memory newOwnersPortion
    ) public view {
        require(
            newOwners.length == newOwnersPortion.length,
            "The portion and address fields must be of equal length"
        );
        Variables.QubitsToken memory qubitsToken = QubitsTokenMap[_tokenId];

        uint256 total = 0;
        for (uint256 i = 0; i < newOwners.length; i++) {
            require(
                newOwners[i] != address(0),
                "Invalid recepient address included"
            );
            require(
                newOwnersPortion[i] <= qubitsToken.portion,
                "You can't transfer more than 100% of your holding"
            );
            total += newOwnersPortion[i];
        }
        require(total == qubitsToken.portion,"Incorrect portion sum");
    }
}

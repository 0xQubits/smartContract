// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../common/Variables.sol";
 
/**
 * @dev A smart contract for storing details about internal qubits tokens
 */
contract QubitsTokenRegistry is AccessControlUpgradeable,UUPSUpgradeable {
 
    mapping(uint256 => Variables.QubitsToken) public QubitsTokenMap;

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
        Variables.QubitsToken[] memory qTokens = new Variables.QubitsToken[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            qTokens[i] = QubitsTokenMap[_tokenIds[i]];
        }
        return qTokens;
    }

    /**
     * @dev Create a token object after a token has been minted and
     * add it to the mapping of token ids to token objects
     */
    function create(
        uint256 _tokenId,
        address _to,
        uint256 _portion,
        bytes32 _hash,
        uint256 _parentId
    ) public {
        Variables.QubitsToken memory token;
        token.id = _tokenId;
        token.owner = _to;
        token.portion = _portion;
        token.hasBeenAltered = false;
        token.externalTokenHash = _hash;
        token.parentId = _parentId;
        QubitsTokenMap[_tokenId] = token;
    }

    /**
     * @dev Set the hasBeenAltered property of a token 
     * object to true so that it can not be reassigned
     */
    function invalidate(
        uint256 _tokenId
    ) public {
        Variables.QubitsToken storage qToken = QubitsTokenMap[_tokenId];
        qToken.hasBeenAltered = true;
    }


    /**
     * @dev Check user and token permissions 
     * before a token is transferred/split
     */
    function checkTransferPermission(
        uint256 _tokenId,
        address _owner
    ) public view {
        Variables.QubitsToken memory qToken = QubitsTokenMap[_tokenId];
        assert(qToken.owner != address(0));
        require(
            qToken.owner == _owner,
            "Only the owner may call this function"
        );
        require(
            qToken.hasBeenAltered == false,
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
        Variables.QubitsToken memory qToken = QubitsTokenMap[_tokenId];

        uint256 total = 0;
        for (uint256 i = 0; i < newOwners.length; i++) {
            require(
                newOwners[i] != address(0),
                "Invalid recepient address included"
            );
            require(
                newOwnersPortion[i] <= qToken.portion,
                "You can't transfer more than 100% of your holding"
            );
            total += newOwnersPortion[i];
        }
        require(total == qToken.portion,"Incorrect portion sum");
    }
}

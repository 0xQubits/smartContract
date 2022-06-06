// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./library/SharedVariable.sol";

contract InternalTokenStorage is Initializable {
    // struct and variables

    mapping(uint => InternalToken) public InternalTokenMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    

    function get(uint _tokenId) public view returns (InternalToken memory) {
        return InternalTokenMap[_tokenId];
    }

    function getArr(uint256[] memory _tokenIds)
        public
        view
        returns (InternalToken[] memory)
    {
        // Gets an array of Qubits token(Token) objects
        // when given an array of token ids
        InternalToken[] memory intTokens = new InternalToken[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            intTokens[i] = InternalTokenMap[_tokenIds[i]];
        }
        return intTokens;
    }

    function create(
        uint256 _tokenId,
        address _to,
        uint256 _portion,
        bytes32 _hash,
        uint256 _parentId
    ) public {
        InternalToken memory token;
        token.id = _tokenId;
        token.owner = _to;
        token.portion = _portion;
        token.hasBeenAltered = false;
        token.externalTokenHash = _hash;
        token.parentId = _parentId;
        InternalTokenMap[_tokenId] = token;
    }

    function invalidate(
        uint _tokenId
    ) public {
        InternalToken storage intToken = InternalTokenMap[_tokenId];
        intToken.hasBeenAltered = true;
    }




    // Permission 

    function checkTransferPermission(
        uint _tokenId
    ) public {
        InternalToken memory intToken = InternalTokenMap[_tokenId];
        assert(intToken.owner != address(0));
        require(
            intToken.owner == msg.sender,
            "Only the owner may call this function"
        );
        require(
            intToken.hasBeenAltered == false,
            "Token may not be altered more than once"
        );
    }


    function validateTransferParameters(
        uint _tokenId,
        address[] memory new_owners,
        uint[] memory new_owners_portion
    ) public returns (uint){
        require(
            new_owners.length == new_owners_portion.length,
            "The portion and address fields must be of equal length"
        );
        InternalToken memory intToken = InternalTokenMap[_tokenId];

        uint256 total = 0;
        for (uint256 i = 0; i < new_owners.length; i++) {
            require(
                new_owners[i] != address(0),
                "Invalid recepient address included"
            );
            require(
                new_owners_portion[i] <= intToken.portion,
                "You can't transfer more than 100% of your holding"
            );
            total += new_owners_portion[i];
        }
        require(total == intToken.portion,"Incorrect portion sum");

    }

    
}

contract ExternalTokenStorage is Initializable {
    // struct and variables

    mapping(bytes32 => ExternalToken) public ExternalTokenMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    function createStart(
        bytes32 _hash,
        address sender,
        address _contract,
        uint256 _tokenId
    ) public {
        ExternalToken storage externalToken = ExternalTokenMap[_hash];
        if (externalToken.senderArr.length != 0) {
            externalToken.senderArr.push(sender);
        } else {
            address[] memory senderArr = new address[](1);
            senderArr[0] = sender;

            externalToken.contract_ = _contract;
            externalToken.senderArr = senderArr;
            externalToken.tokenId = _tokenId;
        }

        // set this so that the mintToken function can access it
        ExternalTokenMap[_hash] = externalToken;
    }

    function createFinish(bytes32 _hash, uint256 _qubitsTokenId) public {
        // add newly created token to active token list
        ExternalToken storage externalToken = ExternalTokenMap[_hash];
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _qubitsTokenId;
        externalToken.activeTokenIdsArr = tokenIds;
    }

    function add(bytes32 _hash, uint256 _tokenId) public returns (uint256) {
        ExternalToken storage externalToken = ExternalTokenMap[_hash];
        assert(externalToken.contract_ != address(0));
        // add transaction to history
        externalToken.historyArr.push(_tokenId);
        return externalToken.tokenId;
    }

    function update(
        bytes32 _hash,
        uint256[] memory incomingTokenIds,
        uint256 outgoingTokenId
    ) public {
        assert(incomingTokenIds.length > 0);
        uint256[] storage activeTokenIds = ExternalTokenMap[_hash].activeTokenIdsArr;
        for (uint256 i = 0; i < activeTokenIds.length; i++) {
            uint256 tokenId = activeTokenIds[i];
            if (tokenId == outgoingTokenId) {
                activeTokenIds[i] = incomingTokenIds[0];
                if (incomingTokenIds.length > 1) {
                    for (uint256 j = 1; j < incomingTokenIds.length; j++) {
                        activeTokenIds.push(incomingTokenIds[j]);
                    }
                    break;
                }
            }
        }
    }

    function get(bytes32 _hash) public view returns (ExternalToken memory) {
        return ExternalTokenMap[_hash];
    }

    function clearActive(bytes32 _hash) public {
        // clear active tokens array
        uint256[] storage activeTokenIdsArr = ExternalTokenMap[_hash]
            .activeTokenIdsArr;
        uint256 len = activeTokenIdsArr.length;
        for (uint256 i = 0; i < len; i++) {
            activeTokenIdsArr.pop();
        }

        assert(activeTokenIdsArr.length == 0);
    }
}

contract ActiveTokenStorage is Initializable {
    // struct and variables

    mapping(address => uint256[]) public UserActiveTokenMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {}

    function update(uint256 tokenId, address formerOwnerAddress) public {
        // change modifier and scope
        uint256[] storage userActiveTokens = UserActiveTokenMap[
            formerOwnerAddress
        ];
        for (uint256 i = 0; i < userActiveTokens.length; i++) {
            if (userActiveTokens[i] == tokenId) {
                //swap and pop
                userActiveTokens[i] = userActiveTokens[
                    userActiveTokens.length - 1
                ];
                userActiveTokens.pop();
                break;
            }
        }
    }

    function add(address to, uint256 tokenId) public {
        uint256[] storage userActiveTokens = UserActiveTokenMap[to];
        userActiveTokens.push(tokenId);
    }

    function get(address _address) public view returns (uint256[] memory) {
        return UserActiveTokenMap[_address];
    }
}

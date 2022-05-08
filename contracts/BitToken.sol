// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract BitToken is ERC721,IERC721Receiver, AccessControl {
    using Counters for Counters.Counter;

    uint public constant DECIMAL = uint(12);
    uint public constant TOTAL = uint(10)**DECIMAL;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;


    
    
    struct Token {
        address owner;
        uint portion;
        bool hasBeenAltered;
        bytes32 externalTokenHash;

    }
    Token[] public TokenArr;

    struct ExternalToken {
        address sender;
        address contract_;
        uint tokenId;
        uint[] historyArr;
        uint[] activeTokenIdsArr;

    }
    mapping(bytes32 => ExternalToken) public ExternalTokenMap;

    event ReceivedExternalToken(address sender ,address operator, address from,uint tokenId,bytes32 hash_value );
    event OwnershipModified(address from ,address to, uint externalTokenId,uint portion );


    

    
    constructor() ERC721("MyToken", "MTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }



    function safeMintToken(
            address from,
            address to,
            uint portion,
            bytes32 externalTokenHash
        ) private returns (uint){
        

        Token memory token;
        token.owner = to;
        token.portion = portion;
        token.externalTokenHash = externalTokenHash;
        TokenArr.push(token);
        
        uint tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        ExternalToken storage externalToken;
        externalToken = ExternalTokenMap[externalTokenHash];
        externalToken.historyArr.push(tokenId);

        emit OwnershipModified(
            from,
            to,
            externalToken.tokenId,
            portion
        );
        return tokenId;

    }

    
    function makeExternalTokenHash(
        address _contract_address,
        uint _tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract_address, _tokenId));
    }



    function modifyTokenOwnership(
        uint _tokenId,
        address[] memory _new_owners, 
        uint[] memory _new_owners_portion

        )  public {
            require(_new_owners.length == _new_owners_portion.length);

            Token storage token = TokenArr[_tokenId];
            require(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may transfer this NFT");
            require(token.hasBeenAltered == false,"Token may not  be altered more than once");
        

            uint total = 0;
            for (uint i=0;i < _new_owners.length;i++){
                require(_new_owners_portion[i] <= token.portion,"You can't transfer more than 100% of your holding");
                total = total + _new_owners_portion[i];
            }
            require(total == token.portion,"Incorrect portion allocation. They sum up to more or less than 100%");

            token.hasBeenAltered = true;
            
            uint[] memory new_divided_token_ids = new uint[](_new_owners.length);


            for (uint i=0;i < _new_owners.length;i++){
                uint new_token_id;
                new_token_id =safeMintToken(
                      token.owner,
                     _new_owners[i],
                     _new_owners_portion[i],
                     token.externalTokenHash
                );
                new_divided_token_ids[i] = new_token_id;
            }
            updateActiveTokenArr(
                token.externalTokenHash,
                _tokenId,
                new_divided_token_ids
            );

            
        
    }



    function getExternalToken(
        address _contract,
        uint _tokenId
    ) public view returns (ExternalToken memory){
        bytes32 hash_value = makeExternalTokenHash(_contract, _tokenId);
        return ExternalTokenMap[hash_value];
    }




    function getToken(
        uint _tokenId
    ) public view returns (Token memory){
        return TokenArr[_tokenId];
    }




    function getTokenArr(
        uint[] memory _tokenIds
    ) public view returns (Token[] memory){
        
        Token[] memory tokens = new Token[](_tokenIds.length);
        for (uint i=0;i<_tokenIds.length;i++){
            tokens[i] = TokenArr[_tokenIds[i]];
        }
        return tokens;
    }
    

     function getActiveTokenIds(
        bytes32 externalTokenHash
    ) public view returns (uint[] memory) {
        ExternalToken memory externalToken = ExternalTokenMap[externalTokenHash]; 
        return externalToken.activeTokenIdsArr;
    }

    function getActiveTokens(
        bytes32 externalTokenHash
    ) public view returns (Token[] memory) {
        ExternalToken memory externalToken = ExternalTokenMap[externalTokenHash];
        uint[] memory activeTokenIdsArr = externalToken.activeTokenIdsArr;

        Token[] memory tokens = new Token[](activeTokenIdsArr.length);
        for (uint i=0;i<activeTokenIdsArr.length;i++){
            tokens[i] = TokenArr[activeTokenIdsArr[i]];
        }
        return tokens;
    }

    


    function updateActiveTokenArr(
        bytes32 externalTokenHash,
        uint outgoingTokenId,
        uint[] memory incomingTokenIds
    ) private {
        require(incomingTokenIds.length > 0,"Incoming Token Ids array must have at least one value");
        
        ExternalToken storage externalToken = ExternalTokenMap[externalTokenHash];
        uint[] storage activeTokenIdsArr = externalToken.activeTokenIdsArr;
        for (uint i=0; i < activeTokenIdsArr.length;i++){
            uint tokenId = activeTokenIdsArr[i];
            if (tokenId == outgoingTokenId){
                delete activeTokenIdsArr[i];
                for (uint j=0;j<incomingTokenIds.length;j++){
                    if (j==0){
                        activeTokenIdsArr[i] = incomingTokenIds[j];
                    } else {
                        activeTokenIdsArr.push(incomingTokenIds[j]);
                    }
                }
            }
        }
    }

    

    

    function returnToken(
        bytes32 externalTokenHash

    ) public returns (bool) {
        

        uint expected_total = 0;
        ExternalToken storage externalToken;
        externalToken =  ExternalTokenMap[externalTokenHash];
        uint[] storage activeTokenIdsArr = externalToken.activeTokenIdsArr;
        
        for (uint i=0;i < activeTokenIdsArr.length;i++){
            uint tokenId = activeTokenIdsArr[i];
            Token storage token = TokenArr[tokenId];
            require(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may transfer this NFT");
            require(token.hasBeenAltered == false,"One token has already been altered ");
            expected_total += token.portion;
        }
        require(expected_total==TOTAL,"You must have 100% ownership of the NFT in order to perform this function");

        ERC721 nft = ERC721(externalToken.contract_);
        nft.transferFrom(address(this),msg.sender,externalToken.tokenId);

        // make sure they they can't be used to send back token twice 
        for (uint i=0;i < activeTokenIdsArr.length;i++){
            Token storage token = TokenArr[activeTokenIdsArr[i]];
            token.hasBeenAltered = true;            
        }
        return true;
    }



    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {

    // check that token has not previoudly been assigned
        ExternalToken memory externalToken;
        externalToken.contract_ = msg.sender;
        externalToken.sender = from;
        externalToken.tokenId = tokenId;
        bytes32 hash_value = makeExternalTokenHash(msg.sender, tokenId);

        uint[] memory new_divided_token_ids = new uint[](1);
        uint new_divided_token_id;
        new_divided_token_id = safeMintToken(
            externalToken.sender,
            externalToken.sender,
            TOTAL,
            hash_value
            );
        
        new_divided_token_ids[0] = new_divided_token_id;
        externalToken.activeTokenIdsArr = new_divided_token_ids;


        ExternalTokenMap[hash_value] = externalToken;
        emit ReceivedExternalToken(msg.sender,operator,from, tokenId,hash_value);

        return this.onERC721Received.selector;
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

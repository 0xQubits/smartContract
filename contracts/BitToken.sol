// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract BitToken is ERC721,IERC721Receiver,Pausable,AccessControl {
    
    // struct and variables
    struct ExternalToken {
        // Stores information on the
        // received External Token
        address sender;
        address contract_;
        uint tokenId;
        uint[] historyArr;
        // Array of the ids of the BitTokens
        // that have not been altered.
        // It effectively stores the
        // BitTokens of all current owners 
        uint[] activeTokenIdsArr; 

    }

    struct Token {
        // Stores BitToken information
        address owner;
        uint portion;
        bool hasBeenAltered;
        bytes32 externalTokenHash;
        uint parentId;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint public constant DECIMAL = uint(12);
    // The value that denotes 100% ownership of an externalToken
    uint public constant TOTAL = uint(10)**DECIMAL; // 10 ^ 12
    mapping(bytes32 => ExternalToken) public ExternalTokenMap;
    Token[] public TokenArr;

    // ROLES
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Events
    event InitializedExternalToken(address contract_ ,address sender, uint tokenId);
    event OwnershipModified(address from ,address to, uint externalTokenId,uint portion );
    


    constructor() ERC721("BitToken", "BIT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }



    function mintToken(
            address from,
            address to,
            uint portion,
            bytes32 externalTokenHash,
            uint parentId
        ) private returns (uint){
        // This is a private function for token mint
        ExternalToken storage externalToken;
        externalToken = ExternalTokenMap[externalTokenHash];
        // make sure external token object exists
        // added this after discovery of a previous bug
        assert(externalToken.contract_ != address(0));

        //////////// Actual Mint ///////////
        // using safeMint can lead to unexpected behaviour
        // if this function is called from a loop and
        // one of the receivers cannot receive the token
        uint tokenId = _tokenIdCounter.current();
        _mint(to, tokenId); 
        _tokenIdCounter.increment();

        
        // create token object and add it 
        // to the array of existing tokens
        Token memory token;
        token.owner = to;
        token.portion = portion;
        token.hasBeenAltered = false;
        token.externalTokenHash = externalTokenHash;
        token.parentId = parentId;
        TokenArr.push(token);
        
        // add transaction to history
        externalToken.historyArr.push(tokenId);

        emit OwnershipModified(from,to,externalToken.tokenId,portion);
        return tokenId;
    }






    function splitTokenOwnership(
        uint _tokenId,
        address[] memory _new_owners, 
        uint[] memory _new_owners_portion

        )  public {
            // This is a public function that spilts ownership 
            // of a BitToken. In order for this to work, the 
            // owner has to reassign 100% of whatever portion 
            // the owner has.
            // E.g if A's token portion is 200 (out of TOTAL),
            // the sum of _new_owners_portion must be 200.
            // This means that if A plan's to retain a portion of it
            // He must also assign a portion to himself 
            require(_new_owners.length == _new_owners_portion.length,"The 'portion' and 'address' fields must be of equal length");

            Token storage token = TokenArr[_tokenId];
            assert(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may transfer this NFT");
            require(token.hasBeenAltered == false,"Token may not  be altered more than once");
        

            uint total = 0;
            for (uint i=0;i < _new_owners.length;i++){
                require(_new_owners[i] != address(0),"There is an invalid recepient address");
                require(_new_owners_portion[i] <= token.portion,"You can't transfer more than 100% of your holding");
                total += _new_owners_portion[i];
            }
            require(total == token.portion,"Incorrect portion allocation. They sum up to more or less than 100%");

            // VERY IMPORTANT to state that
            // token has been modified
            token.hasBeenAltered = true;
            
            uint[] memory newDividedTokenIds = new uint[](_new_owners.length);


            for (uint i=0;i < _new_owners.length;i++){
                uint new_token_id;
                new_token_id =mintToken(
                      token.owner,
                     _new_owners[i],
                     _new_owners_portion[i],
                     token.externalTokenHash,
                     _tokenId
                );
                newDividedTokenIds[i] = new_token_id;
            }
            updateActiveTokenArr(
                token.externalTokenHash,
                _tokenId,
                newDividedTokenIds
            );

            
        
    }

    function makeExternalTokenHash(
        address _contract_address,
        uint _tokenId
    ) public pure returns (bytes32) {
        // constructs hash from external contract address and token id
        return keccak256(abi.encodePacked(_contract_address, _tokenId));
    }



    function getExternalToken(
        bytes32 externalTokenHash
    ) public view returns (ExternalToken memory){
        // Get ExternalToken object using hash
        return ExternalTokenMap[externalTokenHash];
    }




    function getToken(
        uint _tokenId
    ) public view returns (Token memory){
        // Get BitToken using token id 
        return TokenArr[_tokenId];
    }




    function getTokenArr(
        uint[] memory _tokenIds
    ) public view returns (Token[] memory){
        // Gets an array of BitToken(Token) objects
        // when given an array of token ids 
        Token[] memory tokens = new Token[](_tokenIds.length);
        for (uint i=0;i<_tokenIds.length;i++){
            tokens[i] = TokenArr[_tokenIds[i]];
        }
        return tokens;
    }




    function getActiveTokenIds(
        bytes32 externalTokenHash
    ) public view returns (uint[] memory) {
        // Get the ids of all active tokens
        // connected to an ExternalToken
        ExternalToken memory externalToken = ExternalTokenMap[externalTokenHash]; 
        return externalToken.activeTokenIdsArr;
    }


    function getActiveTokenArr(
        bytes32 externalTokenHash
    ) public view returns (Token[] memory) {
        // Get the BitToken(Token) objects of all
        // active tokens connected to an ExternalToken
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
        // This is a private function that updates the 
        // active token array of an ExternalToken object
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
                break;
            }
        }
    }

    

    

    function returnToken(
        bytes32 externalTokenHash

    ) public returns (bool) {
        // This is a public function to take the token out of 
        // this contract and back to the ExternalToken contract

        // The person calling this contract must own all
        // the active tokens connected to the ExternalToken 

        uint expectedTotal = 0;
        ExternalToken storage externalToken;
        externalToken =  ExternalTokenMap[externalTokenHash];
        uint[] storage activeTokenIdsArr = externalToken.activeTokenIdsArr;
        
        for (uint i=0;i < activeTokenIdsArr.length;i++){
            uint tokenId = activeTokenIdsArr[i];
            Token storage token = TokenArr[tokenId];
            require(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may transfer this NFT");
            require(token.hasBeenAltered == false,"One token has already been altered ");
            expectedTotal += token.portion;
        }

        assert(expectedTotal==TOTAL);

        ERC721 externalTokenContract = ERC721(externalToken.contract_);
        externalTokenContract.transferFrom(address(this),msg.sender,externalToken.tokenId);

        // MAKE SURE TO ADD THAT THE TOKENS HAVE BEEN ALTERED
        for (uint i=0;i < activeTokenIdsArr.length;i++){
            Token storage token = TokenArr[activeTokenIdsArr[i]];
            token.hasBeenAltered = true;            
        }
        return true;
    }








    function initializeExternalToken(
        address contract_, 
        address sender,
        uint tokenId,
        bytes32 externalTokenHash 
    ) private {
        // This is a private function to mint a BitToken 
        // representing 100% ownership of an external 
        // token on receipt of the external token
        ExternalToken memory externalToken;

        externalToken.contract_ = contract_;
        externalToken.sender = sender;
        externalToken.tokenId = tokenId;

        // set this so that the mintToken function can access it
        ExternalTokenMap[externalTokenHash] = externalToken;

        uint[] memory newDividedTokenIds = new uint[](1);
        uint newDividedTokenId;
        // uint parentId = 2 ^ 256 - 1;
        uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        newDividedTokenId = mintToken(sender,sender,TOTAL,externalTokenHash,MAX_INT);
        
        newDividedTokenIds[0] = newDividedTokenId;
        ExternalToken storage externalTokenRefreshed = ExternalTokenMap[externalTokenHash];
        externalTokenRefreshed.activeTokenIdsArr = newDividedTokenIds;

        emit InitializedExternalToken(contract_,sender,tokenId);

    }




    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {

        bytes32 externalTokenHash = makeExternalTokenHash(msg.sender, tokenId);
        initializeExternalToken(msg.sender,from,tokenId,externalTokenHash);
        
        return this.onERC721Received.selector;
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

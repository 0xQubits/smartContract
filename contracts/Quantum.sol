// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract Quantum is ERC721,IERC721Receiver,Pausable,AccessControl {
    
    // struct and variables
    struct ExternalToken {
        // Stores information on the
        // received External Token
        address[] senderArr;
        address contract_;
        uint tokenId;
        uint[] historyArr;
        // Quantum token Ids of all current owners 
        uint[] activeTokenIdsArr; 

    }

    struct Token {
        // Stores Quantum token information
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
    event ExternalTokenReturn(address contract_ ,address owner, uint externalTokenId);
    
    //Errors
    error UnImplemented();



    constructor() ERC721("Quantum", "QTM") {
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

        )  public whenNotPaused {
            // This is a public function that spilts ownership 
            // of a Quantum token. In order for this to work, the 
            // owner has to reassign 100% of whatever portion 
            // the owner has.
            // E.g if A's token portion is 200 (out of TOTAL),
            // the sum of _new_owners_portion must be 200.
            // This means that if A plan's to retain a portion of it
            // He must also assign a portion to himself 

            Token storage token = TokenArr[_tokenId];
            assert(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may split this token");
            require(token.hasBeenAltered == false,"Token may not  be altered more than once");
            require(_new_owners.length == _new_owners_portion.length,"The portion and address fields must be of equal length");

            uint total = 0;
            for (uint i=0;i < _new_owners.length;i++){
                require(_new_owners[i] != address(0),"Invalid recepient address included");
                require(_new_owners_portion[i] <= token.portion,"You can't transfer more than 100% of your holding");
                total += _new_owners_portion[i];
            }
            require(total == token.portion,"Incorrect portion allocation. They sum up to more or less than 100%");

            // VERY IMPORTANT to state that
            // token has been modified and 
            // BURN the old token
            token.hasBeenAltered = true;
            _burn(_tokenId);
            
            uint[] memory newlyCreatedTokenIds = new uint[](_new_owners.length);


            for (uint i=0;i < _new_owners.length;i++){
                uint new_token_id;
                new_token_id =mintToken(
                      token.owner,
                     _new_owners[i],
                     _new_owners_portion[i],
                     token.externalTokenHash,
                     _tokenId
                );
                newlyCreatedTokenIds[i] = new_token_id;
            }
            updateActiveTokenArr(
                token.externalTokenHash,
                _tokenId,
                newlyCreatedTokenIds
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




    function getTokenArr(
        uint[] memory _tokenIds
    ) public view returns (Token[] memory){
        // Gets an array of Quantum token(Token) objects
        // when given an array of token ids 
        Token[] memory tokens = new Token[](_tokenIds.length);
        for (uint i=0;i<_tokenIds.length;i++){
            tokens[i] = TokenArr[_tokenIds[i]];
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
        assert(incomingTokenIds.length > 0);
        
        ExternalToken storage externalToken = ExternalTokenMap[externalTokenHash];
        uint[] storage activeTokenIdsArr = externalToken.activeTokenIdsArr;
        for (uint i=0; i < activeTokenIdsArr.length;i++){
            uint tokenId = activeTokenIdsArr[i];
            if (tokenId == outgoingTokenId){
                activeTokenIdsArr[i] = incomingTokenIds[0];
                for (uint j=1;j<incomingTokenIds.length;j++){
                    activeTokenIdsArr.push(incomingTokenIds[j]);
                }
                break;
            }
        }
    }

    

    

    function returnToken(
        bytes32 externalTokenHash

    ) public whenNotPaused {
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
            require(token.owner == msg.sender,"Only the owner may return this token");
            assert(token.hasBeenAltered == false);
            expectedTotal += token.portion;
        }
        assert(expectedTotal==TOTAL);


        for (uint i=0;i < activeTokenIdsArr.length;i++){
            uint tokenId = activeTokenIdsArr[i];
            Token storage token = TokenArr[tokenId];
            token.hasBeenAltered = true; 
            _burn(tokenId);           
        }

        for (uint i=0; i < activeTokenIdsArr.length;i++){
           activeTokenIdsArr.pop();
        }


        uint externalTokenId = externalToken.tokenId;
        address contract_ = externalToken.contract_;
        ERC721 externalTokenContract = ERC721(contract_);
        externalTokenContract.transferFrom(address(this),msg.sender,externalToken.tokenId);

        emit ExternalTokenReturn(contract_, msg.sender, externalTokenId);
    }








    function initializeExternalToken(
        address contract_, 
        address sender,
        uint tokenId,
        bytes32 externalTokenHash 
    ) private whenNotPaused {
        // This is a private function to mint a Quantum token 
        // representing 100% ownership of an external 
        // token on receipt of the external token
        // ExternalToken memory externalToken;
        ExternalToken storage externalToken = ExternalTokenMap[externalTokenHash];
        if (externalToken.senderArr.length != 0){
            externalToken.senderArr.push(sender);

        } else {
            address[] memory senderArr = new address[](1);
            senderArr[0] = sender;

            externalToken.contract_ = contract_;
            externalToken.senderArr = senderArr;
            externalToken.tokenId = tokenId;
        } 
        

        // set this so that the mintToken function can access it
        ExternalTokenMap[externalTokenHash] = externalToken;

        uint[] memory newlyCreatedTokenIds = new uint[](1);
        uint MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint newlyCreatedTokenId = mintToken(sender,sender,TOTAL,externalTokenHash,MAX_INT);
        
        newlyCreatedTokenIds[0] = newlyCreatedTokenId;
        ExternalToken storage externalTokenRefreshed = ExternalTokenMap[externalTokenHash];
        externalTokenRefreshed.activeTokenIdsArr = newlyCreatedTokenIds;

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



    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert UnImplemented();
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        revert UnImplemented();
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

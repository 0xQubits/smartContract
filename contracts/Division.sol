// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
// 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC721/utils/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC721/IERC721Receiver.sol";


contract MyToken is ERC721,IERC721Receiver, AccessControl {
    using Counters for Counters.Counter;

    uint256 public constant DECIMAL = 12;
    uint256 public constant TOTAL = uint256(10)**uint256(DECIMAL);
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;


    
    struct OriginalToken {
        address sender;
        address contract_;
        uint256 tokenId;

 

    }
    struct DividedToken {
        address owner;
        uint256 portion;
        bool has_been_altered;
        bytes32 original_token_hash;

    }
    //          unique_hash
    mapping(bytes32 => OriginalToken) public OriginalTokens;
    DividedToken[] public DividedTokens;


    

    event ReceivedTokenEvent(address sender ,address operator, address from,uint256 tokenId,bytes32 hash_value );
    event DividedTokenEvent(address from ,address to, uint256 tokenId );
    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() ERC721("MyToken", "MTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }



    // function safeMintDividedToken(address from,address to) public onlyRole(MINTER_ROLE) {
    function safeMintDividedToken(
            address from,
            address to,
            uint256 portion,
            bytes32 original_token_hash
        ) public {
        

        uint256 tokenId = _tokenIdCounter.current();
        
        DividedToken memory token;
        token.owner = to;
        token.portion = portion;
        token.original_token_hash = original_token_hash;
        DividedTokens.push(token);
        emit DividedTokenEvent(from,to,tokenId);


        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    
    function hash_func(
        address _contract_address,
        uint256 _tokenId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract_address, _tokenId));
    }



    function divideToken(
        uint256 _tokenId,
        address[] memory _new_owners, 
        uint256[] memory _new_owners_portion // in 1,000,000,000,000
        // bool[] memory _is_transferable

        )  public {
            require(_new_owners.length == _new_owners_portion.length);

            DividedToken storage token = DividedTokens[_tokenId];
            require(token.owner != address(0));
            require(token.owner == msg.sender,"Only the owner may transfer this NFT");
            require(token.has_been_altered == false,"Token may not  be altered more than once");
        

            uint256 total = 0;
            for (uint256 i=0;i < _new_owners.length;i++){
                require(_new_owners_portion[i] <= token.portion,"You can't transfer more than 100% of your holding");
                total = total + _new_owners_portion[i];
            }
            require(total == token.portion,"Incorrect portion allocation. They sum up to more or less than 100%");

            token.has_been_altered = true;
            

            for (uint256 i=0;i < _new_owners.length;i++){
                safeMintDividedToken(
                    token.owner,
                     _new_owners[i],
                     _new_owners_portion[i],
                     token.original_token_hash
                     );
            }

            
        
    }



    function getOriginalToken(
        address _contract,
        uint256 _tokenId
    ) public view returns (OriginalToken memory){
        bytes32 hash_value = hash_func(_contract, _tokenId);
        return OriginalTokens[hash_value];
    }

    function getDividedToken(
        uint256 _tokenId
    ) public view returns (DividedToken memory){
        return DividedTokens[_tokenId];
    }
    

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {

    // check that token has not previoudly been assigned
        OriginalToken memory token;
        token.contract_ = msg.sender;
        token.sender = from;
        token.tokenId = tokenId;

        bytes32 hash_value = hash_func(msg.sender, tokenId);
        OriginalTokens[hash_value] = token;
        emit ReceivedTokenEvent(msg.sender,operator,from, tokenId,hash_value);

        safeMintDividedToken(
                     token.sender,
                     token.sender,
                     TOTAL,
                     hash_value
                     );


        return this.onERC721Received.selector;
    }

    

    function returnToken(
        uint256[] memory _tokenIds

    ) public returns (bool) {
        
        uint256 required_total = TOTAL;

        uint256 total = 0;
        bytes32 last_original_token_hash;
        for (uint256 i=0;i < _tokenIds.length;i++){
            uint256 DTokenId = _tokenIds[i];
            DividedToken storage DToken = DividedTokens[DTokenId];
            require(DToken.owner != address(0));
            require(DToken.owner == msg.sender,"Only the owner may transfer this NFT");
            require(DToken.has_been_altered == false,"One token has already been altered ");

            if (i > 0 ){
                require(DToken.original_token_hash == last_original_token_hash,"Tokens sent point to different contract or token");
            } else {
                last_original_token_hash = DToken.original_token_hash;
            }
            total = total + DToken.portion;
        }
        require(total==required_total,"You must have 100% ownership of the NFT in order to perform this function");
        
        
        OriginalToken storage OToken = OriginalTokens[last_original_token_hash];
    

        ERC721 nft = ERC721(OToken.contract_);
        nft.transferFrom(
                address(this),
                msg.sender,
                OToken.tokenId
            );

        // make sure they they can't be used to send back token twice 
        for (uint256 i=0;i < _tokenIds.length;i++){
            DividedToken storage DToken = DividedTokens[_tokenIds[i]];
            DToken.has_been_altered = true;            
        }
        return true;
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
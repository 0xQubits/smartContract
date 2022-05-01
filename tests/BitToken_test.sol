// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "remix_tests.sol"; // this import is automatically injected by Remix
import "remix_accounts.sol";
import "../contracts/BitToken.sol";


contract TestBitToken {
    /// Define variables referring to different accounts
    address acc0;
    address acc1;
    address acc2;
    uint256 DEFAULT_TOKEN_ID = 1;
    BitToken bitToken = new BitToken();
    GameItem game = new GameItem();
    
    /// Initiate accounts variable
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);

        

    
        game.awardItem(address(this)); //mint
        Assert.equal(game.ownerOf(DEFAULT_TOKEN_ID),address(this), "NFT should be owned by the this contract");
        
    }

    
    

    function testInitialization() public {
        // Ensure that the NFT can be sent to the BitToken contract
        // and 100% ownership is originally assigned to the sender of the NFT
        game.safeTransferFrom(
            address(this),
            address(bitToken),
            DEFAULT_TOKEN_ID
        );

        BitToken.OriginalToken memory original_token = bitToken.getOriginalToken(address(game),DEFAULT_TOKEN_ID);
        Assert.equal(original_token.contract_,address(game), "The original token contract should be the game address");
        Assert.equal(original_token.sender,address(this), "The original token sender should be this contract's address");
        Assert.equal(original_token.tokenId,uint(1), "The original tokenId should be 1");


        BitToken.DividedToken memory first_divided_token = bitToken.getDividedToken(uint(0));
        Assert.equal(first_divided_token.owner,address(this), "The divided token owner should be this contract's address");
        Assert.equal(first_divided_token.portion,  uint256(10)**uint256(12), "The new owner's total portion should be 100% ");
        Assert.equal(first_divided_token.has_been_altered, false, "The divided token should not have been altered");
        // Assert.equal(first_divided_token.original_token_hash, false, "The divided token should not have been altered");
        
        
    }

    function testSecondDivision() public {
        // Ensure that the NFT can be further divided
        // after initialization and ensure that it is 
        // sent to the intended new owners 

        address[] memory new_owners = new address[](4);
        new_owners[0] = address(acc0);
        new_owners[1] = address(acc1);
        new_owners[2] = address(acc2);
        new_owners[3] = address(acc0);
        
      
        // the portion must be a total of 10 ** 12
        uint[] memory new_owners_portion = new uint[](4);
        new_owners_portion[0] = uint(4) * (uint(10) **uint(11));
        new_owners_portion[1] = uint(3) * (uint(10) **uint(11));
        new_owners_portion[2] = uint(2) * (uint(10) **uint(11));
        new_owners_portion[3] = uint(1) * (uint(10) **uint(11));


        // the actual division                
        bitToken.divideToken(
            uint(0),
            new_owners,
            new_owners_portion
        );

    
        BitToken.DividedToken memory first_divided_token = bitToken.getDividedToken(uint(0)); 
        Assert.equal(first_divided_token.has_been_altered, true, "The first divided token should now be altered");




        for (uint i=1; i < 5 ;i++){
            BitToken.DividedToken memory new_divided_token = bitToken.getDividedToken(uint(i));
            Assert.equal(new_divided_token.owner,new_owners[i-1], "The divided token owner should be the new owner");
            Assert.equal(new_divided_token.portion,  new_owners_portion[i-1], "The new owner's total portion should be the new one ");
            Assert.equal(new_divided_token.has_been_altered, false, "The divided token should not have been altered");

        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
  
}
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


    

    function testInitialDivision() public {
        game.safeTransferFrom(
            address(this),
            address(bitToken),
            DEFAULT_TOKEN_ID
        );

        BitToken.OriginalToken memory original_token = bitToken.getOriginalToken(address(game),DEFAULT_TOKEN_ID);
        Assert.equal(original_token.contract_,address(game), "The original token contract should be the game address");
        Assert.equal(original_token.sender,address(this), "The original token sender should be this contract's address");
        Assert.equal(original_token.tokenId,1, "The original tokenId should be 1");


        BitToken.DividedToken memory divided_token = bitToken.getDividedToken(0);
        Assert.equal(divided_token.owner,address(this), "The divided token owner should be this contract's address");
        Assert.equal(divided_token.portion,  uint256(10)**uint256(12), "The new owner's total portion should be 100% ");
        Assert.equal(divided_token.has_been_altered, false, "The divided token should not have been altered");
        // Assert.equal(divided_token.original_token_hash, false, "The divided token should not have been altered");


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
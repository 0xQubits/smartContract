// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;
// for Game Item
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";




/** @dev NFT for testing */
contract Game is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Game", "ITM") {}

    function awardItem(address player)
        public
        returns (uint256)
    {

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _tokenIds.increment();
        _setTokenURI(newItemId, "");

        return newItemId;
    }
}
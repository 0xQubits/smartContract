// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;
// for Game Item
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";




/** @dev Malicious NFT for testing
 *
 * We use this contract to test what will happen if 
 * no token is transferred to Qubits contract but 
 * but the onERC721Received method is called
 */
contract MaliciousGame is ERC721URIStorage {
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

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // do nothing
    }


}
// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./registry/OtherTokenRegistry.sol";
import "./registry/QubitsTokenRegistry.sol";
import "./registry/UserQubitsTokenRegistry.sol";
import "./common/library/Utils.sol";
import "./common/library/Variables.sol";
import "./common/abstract/access/CustomAccessUpgradeable.sol";


/**
 * @title Qubits 
 * @author Lanre Ojetokun { lojetokun@gmail.com }
 * @dev The main contract for receiving and splitting nft ownership
 * 
 *  In order to start splitting your nft, you must call the safeTransferFrom method
 *  of the ERC721 contract that the nft is being transferred from  
 * [CAUTION] ====
 *      Only the safeTransferFrom method must be called and not the transferFrom method
 *      as that is the only way the onERC721Received function of this smart contract will 
 *      be called, which is where we perform initialization operations
 *  =====
 * @dev the main public functions that can be called are:
 *
 * (1) splitTokenOwnership: used to split ownership of an already initialized nft
 *
 * (2) restoreTokenOwnership: used to return the token from qubits smart contract back to the
 *                whoever owns 100% of the nft on this smart contract
 */
contract Qubits is
    ERC721Upgradeable,
    IERC721ReceiverUpgradeable,
    CustomAccessUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    address userQubitsTokenRegistryAddress;
    address otherTokenRegistryAddress;
    address qubitsTokenRegistryAddress;


    error Disabled();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _qubitsTokenRegistryAddress,
        address _otherTokenRegistryAddress,
        address _userQubitsTokenRegistryAddress
    ) public initializer {
        __ERC721_init("Qubits", "QTK");
        __CustomAccessUpgradeable_init();
        userQubitsTokenRegistryAddress = _userQubitsTokenRegistryAddress;
        otherTokenRegistryAddress = _otherTokenRegistryAddress;
        qubitsTokenRegistryAddress = _qubitsTokenRegistryAddress;
    }

    



    /**
     * @dev This is an external public function to split ownership of a Qubits token 
     *
     * @param splitQubitsTokenId the id of the token to be split
     * @param newOwners array of new owners addresses
     * @param newOwnersPortion array of portion of each owner
     */
    function splitTokenOwnership(
        uint256 splitQubitsTokenId,
        address[] memory newOwners,
        uint256[] memory newOwnersPortion
    ) external whenNotPaused {
        QubitsTokenRegistry qTokenContract = QubitsTokenRegistry(
            qubitsTokenRegistryAddress
        );
        qTokenContract.checkTransferPermission(splitQubitsTokenId,msg.sender);
        qTokenContract.validateTransferParameters(
            splitQubitsTokenId,
            newOwners,
            newOwnersPortion
        );

        Variables.QubitsToken memory qToken = qTokenContract.get(splitQubitsTokenId);

        _destroyQubitsToken(splitQubitsTokenId, msg.sender);

        uint256[] memory newlyCreatedTokenIds = new uint256[](newOwners.length);
        for (uint256 i = 0; i < newOwners.length; i++) {
            uint256 _mintedQubitsTokenId = _mintQubitsToken(
                newOwners[i],
                newOwnersPortion[i],
                qToken.externalTokenHash,
                splitQubitsTokenId
            );
            newlyCreatedTokenIds[i] = _mintedQubitsTokenId;
        }

        OtherTokenRegistry(otherTokenRegistryAddress).handleTokenSplit(
            qToken.externalTokenHash,
            splitQubitsTokenId,
            newlyCreatedTokenIds
        );
    }

    


    /**
     * @dev This is an external public function to take an nft back from 
     * this contract and back to whoever owns 100% of the nft
     *
     * Note: The person (address) calling this contract must own all
     * the active tokens connected to the nft. That is, they have ownership
     * of tokens that sum up to 100% ownership of the nft
     */
    function restoreTokenOwnership(
        bytes32 otherTokenHash
        ) external whenNotPaused {

        OtherTokenRegistry otherTokenRegistry = OtherTokenRegistry(
            otherTokenRegistryAddress
        );
        QubitsTokenRegistry internalStorageContract = QubitsTokenRegistry(
            qubitsTokenRegistryAddress
        );

        uint256[] memory activeTokenIdsArr = otherTokenRegistry
            .get(otherTokenHash)
            .activeTokenIdsArr;

        assert(activeTokenIdsArr.length > 0);
        // assert iswithus
        uint256 expectedTotal = 0;

        for (uint256 i = 0; i < activeTokenIdsArr.length; i++) {
            uint256 tokenId = activeTokenIdsArr[i];
            Variables.QubitsToken memory qToken = internalStorageContract.get(tokenId);
            internalStorageContract.checkTransferPermission(tokenId,msg.sender);
            expectedTotal += qToken.portion;
        }
        assert(expectedTotal == Variables.FULL_OWNERSHIP_VALUE);

        assert(activeTokenIdsArr.length > 0);
        for (uint256 i = 0; i < activeTokenIdsArr.length; i++) {
            uint256 tokenId = activeTokenIdsArr[i];
            Variables.QubitsToken memory qToken = internalStorageContract.get(tokenId);
            _destroyQubitsToken(qToken.id, msg.sender);
        }

        otherTokenRegistry.handleTokenExit(otherTokenHash);

        Variables.ReceivedToken memory externalToken = otherTokenRegistry.get(
            otherTokenHash
        );
        uint256 externalTokenId = externalToken.tokenId;
        address contract_ = externalToken.contract_;
        ERC721 externalTokenContract = ERC721(contract_);
        externalTokenContract.transferFrom(
            address(this),
            msg.sender,
            externalTokenId
        );

    }

    /** @dev Ensure qubits tokens can't be interacted with
     * or transferred like any other nft except through the 
     * other allowed public functions
     */
    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) public virtual override {
        revert Disabled();
    }


    /** @dev Ensure qubits tokens can't be interacted with
     * or transferred like any other nft except through the 
     * other allowed public functions
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes memory /*_data*/
    ) public virtual override {
        revert Disabled();
    }

    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        _receiveNFT(msg.sender, from, tokenId);
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    /** 
     * @dev Receive an nft from another smart contract and 
     * mint a Qubits token representing 100% ownership of a received nft
     * @param contract_ the contract that called the safeTransferFrom method
     * @param owner address of nft owner
     * @param nft - the nft id  
     */
    function _receiveNFT(
        address contract_,
        address owner,
        uint256 nft
    ) private whenNotPaused {

        bytes32 otherTokenHash = Utils.makeHash(msg.sender,nft);
    
        uint256 mintedQubitsTokenId = _mintQubitsToken(
            owner,
            Variables.FULL_OWNERSHIP_VALUE,
            otherTokenHash,
            Variables.MAX_INT
        );
        OtherTokenRegistry(otherTokenRegistryAddress)
            .handleTokenMint(
                otherTokenHash,
                owner, 
                contract_,
                nft,
                mintedQubitsTokenId
            );
    }

    function _mintQubitsToken(
        address to,
        uint256 portion,
        bytes32 hash_,
        uint256 parentId
    ) private returns (uint256) {
        // @note: using safeMint can lead to unexpected behaviour
        uint256 qubitsTokenId = _tokenIdCounter.current();
        _mint(to, qubitsTokenId);
        _tokenIdCounter.increment();
        QubitsTokenRegistry(qubitsTokenRegistryAddress).create(
            qubitsTokenId,
            to,
            portion,
            hash_,
            parentId
        );
        UserQubitsTokenRegistry(userQubitsTokenRegistryAddress).add(to, qubitsTokenId);
        
        return qubitsTokenId;

    }   

    function _destroyQubitsToken(
        uint tokenId,
        address ownerAddress
        )
        private
    {
        // update state of altered token
        _burn(tokenId);

        QubitsTokenRegistry qTokenStorageContract = QubitsTokenRegistry(qubitsTokenRegistryAddress); 
        qTokenStorageContract.invalidate(tokenId);
        UserQubitsTokenRegistry(userQubitsTokenRegistryAddress).remove(
            ownerAddress,
            tokenId
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

}

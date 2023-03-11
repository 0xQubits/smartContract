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
 *  In order to start splitting ownership of your nft, you must call the safeTransferFrom
 *  method of the ERC721 contract that the nft is being transferred from  
 * [CAUTION] 
 *  ====
 *      Only the safeTransferFrom method must be called when sending an nft to qubits 
 *      and not the transferFrom method as that is the only way the onERC721Received
 *      function of this smart contract will be called, which is where we perform
 *      initialization operations
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
     *
     * [SECURITY CONSIDERATION]
     * ====
     * there are two safeTransferFrom methods in the ERC721 parent contract 
     * and this safeTransferFrom method being overriden is the one that 
     * takes bytes as a parameter because it is called if either of them is called
     * ====
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes memory /*_data*/
    ) public virtual override {
        revert Disabled();
    }



    /**
     * @dev 
     * [SECURITY CONSIDERATIONS]
     *  ====
     *  If this function is called manually by a sender that
     *  is not a contract, execution will be reverted automatically.
     *
     *  If it is called by a non ERC721 contract, this function will revert execution.
     *
     *  If this function is called manually by a smart contract, which hasn't already 
     *  sent the nft to qubits, the call will fail the ERC721(msg.sender).ownerOf test
     *  ==== 
     */
    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override whenNotPaused returns (bytes4) {
        try ERC721(msg.sender).ownerOf(tokenId) returns (address _owner) {
            require(_owner == address(this),"Token not received");   
        } catch {
            revert("Non ERC721 implementer");
        }
        _initializeToken(msg.sender, from, tokenId);

        return this.onERC721Received.selector;
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
        QubitsTokenRegistry qubitsRegistry = QubitsTokenRegistry(
            qubitsTokenRegistryAddress
        );
        qubitsRegistry.checkTransferPermission(splitQubitsTokenId,msg.sender);
        qubitsRegistry.validateTransferParameters(
            splitQubitsTokenId,
            newOwners,
            newOwnersPortion
        );

        Variables.QubitsToken memory qubitsToken = qubitsRegistry.get(splitQubitsTokenId);

        _destroyQubitsToken(splitQubitsTokenId, msg.sender);

        uint256[] memory newlyCreatedTokenIds = new uint256[](newOwners.length);
        for (uint256 i = 0; i < newOwners.length; i++) {
            uint256 _mintedQubitsTokenId = _mintQubitsToken(
                newOwners[i],
                newOwnersPortion[i],
                qubitsToken.externalTokenHash,
                splitQubitsTokenId
            );
            newlyCreatedTokenIds[i] = _mintedQubitsTokenId;
        }

        OtherTokenRegistry(otherTokenRegistryAddress).handleTokenSplit(
            qubitsToken.externalTokenHash,
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
        QubitsTokenRegistry qubitsTokenRegistry = QubitsTokenRegistry(
            qubitsTokenRegistryAddress
        );

        uint256[] memory activeQubitsTokens = otherTokenRegistry
            .get(otherTokenHash)
            .activeQubitsTokens;

        assert(activeQubitsTokens.length > 0);
        // assert iswithus
        uint256 expectedTotal = 0;

        for (uint256 i = 0; i < activeQubitsTokens.length; i++) {
            uint256 tokenId = activeQubitsTokens[i];
            Variables.QubitsToken memory qubitsToken = qubitsTokenRegistry.get(tokenId);
            qubitsTokenRegistry.checkTransferPermission(tokenId,msg.sender);
            expectedTotal += qubitsToken.portion;
        }
        assert(expectedTotal == Variables.FULL_OWNERSHIP_VALUE);

        assert(activeQubitsTokens.length > 0);
        for (uint256 i = 0; i < activeQubitsTokens.length; i++) {
            uint256 tokenId = activeQubitsTokens[i];
            Variables.QubitsToken memory qubitsToken = qubitsTokenRegistry.get(tokenId);
            _destroyQubitsToken(qubitsToken.id, msg.sender);
        }

        otherTokenRegistry.handleTokenExit(otherTokenHash);

        Variables.OtherToken memory externalToken = otherTokenRegistry.get(
            otherTokenHash
        );
        uint256 externalTokenId = externalToken.tokenId;
        address contract_ = externalToken.contract_;
        ERC721 nftContract = ERC721(contract_);
        nftContract.transferFrom(
            address(this),
            msg.sender,
            externalTokenId
        );

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

  


    /** 
     * @dev Receive an nft from another smart contract and 
     * mint a Qubits token representing 100% ownership of a received nft
     * @param contract_ the contract that called the safeTransferFrom method
     * @param owner address of previous nft owner (since current owner is this smart contract)
     * @param tokenId - the nft id  
     */
    function _initializeToken(
        address contract_,
        address owner,
        uint256 tokenId
    ) private {

        bytes32 otherTokenHash = Utils.makeHash(msg.sender,tokenId);
        require(
            !OtherTokenRegistry(otherTokenRegistryAddress)
            .isInitialized(otherTokenHash),
            "Already Initialized"
        );

        uint256 mintedQubitsTokenId = _mintQubitsToken(
            owner,
            Variables.FULL_OWNERSHIP_VALUE,
            otherTokenHash,
            Variables.MAX_INT
        );
        OtherTokenRegistry(otherTokenRegistryAddress)
            .handleTokenInitialization(
                otherTokenHash,
                owner, 
                contract_,
                tokenId,
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

        QubitsTokenRegistry(qubitsTokenRegistryAddress)
            .create(
                qubitsTokenId,
                to,
                portion,
                hash_,
                parentId
            );
        UserQubitsTokenRegistry(userQubitsTokenRegistryAddress)
            .add(to, qubitsTokenId);
        
        return qubitsTokenId;

    }   

    function _destroyQubitsToken(
        uint256 qubitsTokenId,
        address ownerAddress
        )
        private
    {
        _burn(qubitsTokenId);

        QubitsTokenRegistry(qubitsTokenRegistryAddress)
            .invalidate(qubitsTokenId);
        UserQubitsTokenRegistry(userQubitsTokenRegistryAddress)
            .remove(
                ownerAddress,
                qubitsTokenId
            );
    }



}

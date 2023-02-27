// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./registry/OtherTokenRegistry.sol";
import "./registry/QubitsTokenRegistry.sol";
import "./registry/UserQubitsTokenRegistry.sol";
import "./library/Utils.sol";
import "./common/Variables.sol";



contract Qubits is
    ERC721Upgradeable,
    IERC721ReceiverUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public constant DECIMAL = uint256(12);
    // This value that denotes 100% ownership of an externalToken
    uint256 public constant TOTAL = uint256(10)**DECIMAL; // 10 ^ 12

    address userQubitsTokenRegistryAddress;
    address otherTokenRegistryAddress;
    address qubitsTokenRegistryAddress;

    uint256 public constant MAX_INT = uint256(2**256 - 1);

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
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Variables.PAUSER_ROLE, msg.sender);
        _grantRole(Variables.UPGRADER_ROLE, msg.sender);

        userQubitsTokenRegistryAddress = _userQubitsTokenRegistryAddress;
        otherTokenRegistryAddress = _otherTokenRegistryAddress;
        qubitsTokenRegistryAddress = _qubitsTokenRegistryAddress;
    }

    



    /**
     * @dev This is a public function to split ownership of a Qubits token 
     *
     * @param splitQubitsTokenId the id of the token to be split
     * @param newOwners array of new owners addresses
     * @param newOwnersPortion array of portion of each owner
     */
    function splitTokenOwnership(
        uint256 splitQubitsTokenId,
        address[] memory newOwners,
        uint256[] memory newOwnersPortion
    ) public whenNotPaused {
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
     * @dev This is a public function to take an nft back from 
     * this contract and back to the contract that sent the token
     *
     * Note: The person (address) calling this contract must own all
     * the active tokens connected to the ReceivedToken
     */
    function returnToken(bytes32 otherTokenHash) public whenNotPaused {

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
        assert(expectedTotal == TOTAL);

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



 

    function pause() public onlyRole(Variables.PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(Variables.PAUSER_ROLE) {
        _unpause();
    }

    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) public virtual override {
        revert Disabled();
    }

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
            TOTAL,
            otherTokenHash,
            MAX_INT
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

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(Variables.UPGRADER_ROLE)
    {}


}

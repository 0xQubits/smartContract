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
import "./library/Utils.sol";
import "./library/SharedVariable.sol";
import "./Storage.sol";

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
    // The value that denotes 100% ownership of an externalToken
    uint256 public constant TOTAL = uint256(10)**DECIMAL; // 10 ^ 12

    // external contract addresses
    address activeTokenAddress;
    address externalTokenStorageAddress;
    address internalTokenStorageAddress;

    // ROLES
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Events
    event InitializedExternalToken(
        address contract_,
        address sender,
        uint256 tokenId
    );
    event OwnershipModified(
        address from,
        address to,
        uint256 externalTokenId,
        uint256 portion
    );
    event ExternalTokenReturn(
        address contract_,
        address owner,
        uint256 externalTokenId
    );

    //Errors
    error UnImplemented();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _activeTokenAddress,
        address _externalTokenStorageAddress,
        address _internalTokenStorageAddress
    ) public initializer {
        __ERC721_init("Qubits", "QTK");
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        activeTokenAddress = _activeTokenAddress;
        externalTokenStorageAddress = _externalTokenStorageAddress;
        internalTokenStorageAddress = _internalTokenStorageAddress;
    }

    function mintToken(
        address from,
        address to,
        uint256 portion,
        bytes32 _hash,
        uint256 parentId
    ) private returns (uint256) {
        // This is a private function for token mint

        // using safeMint can lead to unexpected behaviour
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _tokenIdCounter.increment();

        // create internal token object
        InternalTokenStorage(internalTokenStorageAddress).create(
            tokenId,
            to,
            portion,
            _hash,
            parentId
        );

        //update external token storage
        uint256 exTokenId = ExternalTokenStorage(externalTokenStorageAddress)
            .add(_hash, tokenId);

        // update user active token map
        ActiveTokenStorage(activeTokenAddress).add(to, tokenId);

        emit OwnershipModified(from, to, exTokenId, portion);
        return tokenId;
    }

    function splitTokenOwnership(
        uint256 _tokenId,
        address[] memory _new_owners,
        uint256[] memory _new_owners_portion
    ) public whenNotPaused {
        // This is a public function that spilts ownership of a Qubits token. 

        InternalTokenStorage intTokenContract = InternalTokenStorage(
            internalTokenStorageAddress
        );


        intTokenContract.checkTransferPermission(_tokenId);
        intTokenContract.validateTransferParameters(
            _tokenId,
            _new_owners,
            _new_owners_portion
        );

        InternalToken memory intToken = intTokenContract.get(_tokenId);

        updateTransferredInternalToken(_tokenId, msg.sender);

        uint256[] memory newlyCreatedTokenIds = new uint256[](
            _new_owners.length
        );

        for (uint256 i = 0; i < _new_owners.length; i++) {
            uint256 new_token_id;
            new_token_id = mintToken(
                intToken.owner,
                _new_owners[i],
                _new_owners_portion[i],
                intToken.externalTokenHash,
                _tokenId
            );
            newlyCreatedTokenIds[i] = new_token_id;
        }

        // update external token active token ids arr
        ExternalTokenStorage(externalTokenStorageAddress).update(
            intToken.externalTokenHash,
            newlyCreatedTokenIds,
            _tokenId
        );
    }

    

    function updateTransferredInternalToken(
        uint tokenId,
        address formerOwnerAddress
        )
        private
    {
        // update state of altered token
        _burn(tokenId);

        InternalTokenStorage intTokenStorageContract = InternalTokenStorage(internalTokenStorageAddress); 
        intTokenStorageContract.invalidate(tokenId);
        ActiveTokenStorage(activeTokenAddress).update(
            tokenId,
            formerOwnerAddress
        );
    }

    function returnToken(bytes32 externalTokenHash) public whenNotPaused {
        // This is a public function to take the token out of
        // this contract and back to the ExternalToken contract

        // The person calling this contract must own all
        // the active tokens connected to the ExternalToken

        ExternalTokenStorage externalStorageContract = ExternalTokenStorage(
            externalTokenStorageAddress
        );
        InternalTokenStorage internalStorageContract = InternalTokenStorage(
            internalTokenStorageAddress
        );

        uint256[] memory activeTokenIdsArr = externalStorageContract
            .get(externalTokenHash)
            .activeTokenIdsArr;

        assert(activeTokenIdsArr.length > 0);
        uint256 expectedTotal = 0;

        for (uint256 i = 0; i < activeTokenIdsArr.length; i++) {
            uint256 tokenId = activeTokenIdsArr[i];
            InternalToken memory intToken = internalStorageContract.get(tokenId);
            internalStorageContract.checkTransferPermission(tokenId);
            expectedTotal += intToken.portion;
        }
        assert(expectedTotal == TOTAL);

        assert(activeTokenIdsArr.length > 0);
        for (uint256 i = 0; i < activeTokenIdsArr.length; i++) {
            uint256 tokenId = activeTokenIdsArr[i];
            InternalToken memory intToken = internalStorageContract.get(tokenId);
            updateTransferredInternalToken(intToken.id, msg.sender);
        }

        externalStorageContract.clearActive(externalTokenHash);

        ExternalToken memory externalToken = externalStorageContract.get(
            externalTokenHash
        );
        uint256 externalTokenId = externalToken.tokenId;
        address contract_ = externalToken.contract_;
        ERC721 externalTokenContract = ERC721(contract_);
        externalTokenContract.transferFrom(
            address(this),
            msg.sender,
            externalTokenId
        );

        emit ExternalTokenReturn(contract_, msg.sender, externalTokenId);
    }

    function initializeExternalToken(
        address contract_,
        address sender,
        uint256 tokenId,
        bytes32 externalTokenHash
    ) private whenNotPaused {
        // This is a private function to mint a Qubits token
        // representing 100% ownership of an external
        // token on receipt of the external token
        // ExternalToken memory externalToken;
        ExternalTokenStorage exTokenStorageContract = ExternalTokenStorage(
            externalTokenStorageAddress
        );
        exTokenStorageContract.createStart(
            externalTokenHash,
            sender,
            contract_,
            tokenId
        );

        uint256 MAX_INT = uint256(2**256 - 1);
        uint256 newTokenId = mintToken(
            sender,
            sender,
            TOTAL,
            externalTokenHash,
            MAX_INT
        );

        exTokenStorageContract.createFinish(externalTokenHash, newTokenId);

        emit InitializedExternalToken(contract_, sender, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        bytes32 externalTokenHash = Utils.makeHash(tokenId);
        initializeExternalToken(msg.sender, from, tokenId, externalTokenHash);

        return this.onERC721Received.selector;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
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

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

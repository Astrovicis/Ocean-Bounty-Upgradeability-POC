pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract ContractSystem is Ownable() {

    mapping(uint256=>ContractCollection) contractCollections;
    mapping(address=>uint256) contractToType;
    mapping(uint256=>bytes32) contractTypeToLibraryName;
    uint256[] allCollections;
    uint256 currentCollection;

    // Contains info for a version of Platform
    struct ContractCollection {
        bool exists;
        mapping(bytes32=>ContractData) contracts;
        bytes32[] allContracts;
    }

    // Stores information about a currently deployed contract or library
    struct ContractData {
        address location;
        address currentVersion;
        mapping(uint256=>mapping(bytes32=>CallTranslationData)) callTranslationData;
    }

    // Used to transform calls on a MatryxTrinity to its relevant library
    struct CallTranslationData {
        address libraryLocation;   // library location
        bytes32 librarySelector;   // library selector
        uint256[] injectedParams;  // what storage slots to insert
        uint256[] dynamicParams;   // what params are dynamic
    }

    modifier onlyOwnerOrStorage {
        bool isOwner = msg.sender == owner;
        bool isStorage = contractToType[msg.sender] == uint256(LibSystem.ContractType.Storage);
        require(isOwner || isStorage, "Must be owner or Platform");
        _;
    }

    /// @dev Checks the validity of a contract address
    function hasCode(address _address) private view returns (bool) {
        uint256 _size;
        assembly { _size := extcodesize(_address) }
        return _size > 0;
    }

    /// @dev Create a new collection of contracts
    function createCollection(uint256 collection) public onlyOwner {
        require(!contractCollections[collection].exists, "Version already exists");
        contractCollections[collection].exists = true;
        allCollections.push(collection);
    }

    /// @dev Set the current contract collection
    function setCollection(uint256 collection) public onlyOwner {
        require(contractCollections[collection].exists, "Version must exist");
        currentCollection = collection;
    }

    /// @dev Get the current version of Platform
    function getCurrentCollection() public view returns (uint256) {
        return currentCollection;
    }

    /// @dev Get all versions of Platform
    function getAllCollections() public view returns (uint256[] memory) {
        return allCollections;
    }

    /// @dev Set a contract address for a contract by a given name
    /// @param version   Version of the contract
    /// @param name      Name of the contract we want to set an address for
    /// @param cAddress  Address of the contract
    function setContract(uint256 collection, uint256 version, bytes32 name, address cAddress) public onlyOwner {
        require(contractCollections[collection].exists, "No such version");
        require(hasCode(cAddress), "Invalid contract address");

        if (contractCollections[collection].contracts[name].location == address(0)) {
            contractCollections[collection].allContracts.push(name);
        }

        contractCollections[collection].contracts[name].location = cAddress;
    }

    /// @dev Returns the address of a contract given its name
    /// @param name     Name of the contract we want an address for
    /// @param version  Version of Platform to lookup the address on
    /// @return         Address of the contract
    function getContract(uint256 collection, uint256 version, bytes32 name) public view returns (address) {
        address cAddress = contractCollections[collection].contracts[name].location;
        require(hasCode(cAddress), "Invalid contract address");

        return cAddress;
    }

    /// @dev Register a library method for a library by its name
    /// @param version   Version of Platform for contract method association
    /// @param libName   Name of the contract to register a method for
    /// @param selector  Hash of the method signature to register to the contract (keccak256)
    /// @param callTranslationData    Calldata transformation information for library delegatecall
    function addCallTranslation(uint256 collection, uint256 version, bytes32 libName, bytes32 selector, CallTranslationData memory callTranslationData) public onlyOwner {
        require(contractCollections[collection].exists, "No such version");
        contractCollections[collection].contracts[libName].callTranslationData[version][selector] = callTranslationData;
    }

    /// @dev Batch register library methods for a library by its name, that share the same injected and dynamic params
    /// @param version            Version of Platform for contract method association
    /// @param libName            Name of the contract we want an address for
    /// @param selectors          Hashes (keccak256) of the method signatures to register to the library 
    /// @param librarySelectors   Hashes (keccak256) of the library-specific method signatures to register to the contract
    /// @param callTranslationData         Calldata transformation information for library delegatecall
    function addCallTranslations(uint256 collection, uint256 version, bytes32 libName, bytes32[] memory selectors, bytes32[] memory librarySelectors, CallTranslationData memory callTranslationData) public onlyOwner {
        require(contractCollections[collection].exists, "No such version");
        require(selectors.length == librarySelectors.length, "List of selectors must match in length");

        for (uint256 i = 0; i < selectors.length; i++) {
            contractCollections[collection].contracts[libName].callTranslationData[version][selectors[i]] = callTranslationData;
            contractCollections[collection].contracts[libName].callTranslationData[version][selectors[i]].librarySelector = librarySelectors[i];
        }
    }

    /// @dev Gets calldata translation data given a library (name or type) and function selector
    /// @param version     Version of Platform for the method request
    /// @param identifier  Name of the contract to give translation data to
    /// @param selector    Hash of the method signature to register to the contract (keccak256)
    /// @return            Calldata transformation information for library delegatecall
    function getCallTranslation(uint256 collection, uint256 version, bytes32 identifier, bytes32 selector) public view returns (CallTranslationData memory) {
        /* contract name identifier */
        // assume 'identifier' is a library name (i.e. 'libDIDRegistry' )
        bytes32 libraryName = identifier;
        CallTranslationData memory translationData = getTranslationData(collection, version, libraryName, selector);

        /* contract address identifier */
        // assume 'identifier' is a contract address
        address addressIdentifier;
        assembly { addressIdentifier := identifier }
        libraryName = contractTypeToLibraryName[contractToType[addressIdentifier]];
        translationData = translationData.libraryLocation == address(0) ? getTranslationData(collection, version, libraryName, selector) : translationData;

        /* EOA identifier */
        // assume 'identifier' is an end user address (use caller address)
        libraryName = contractTypeToLibraryName[contractToType[msg.sender]];
        translationData = translationData.libraryLocation == address(0) ? getTranslationData(collection, version, libraryName, selector) : translationData;

        return translationData;
    }

    function getTranslationData(uint256 collection, uint256 version, bytes32 libraryName, bytes32 selector) internal view returns (CallTranslationData memory) {
        ContractData storage contractData = contractCollections[collection].contracts[libraryName];
        CallTranslationData memory translationData = contractData.callTranslationData[version][selector];
        // create the callTranslationData with the correct library address
        translationData.libraryLocation = translationData.libraryLocation == address(0) ? contractData.location : translationData.libraryLocation;
        if(translationData.libraryLocation != address(0))
        {
            require(hasCode(translationData.libraryLocation), "Invalid contract address");
        }
        
        return translationData;
    }

    /// @dev Associates a contract address with a type
    /// @param contractAddress  Address of the contract we want to set the type
    /// @param contractType     Type we want to associate the contract address with
    function setContractType(uint256 collection, address contractAddress, uint256 contractType) public onlyOwnerOrStorage {
        require(hasCode(contractAddress), "Invalid contract address");
        contractToType[contractAddress] = contractType;
    }

    /// @dev Gets the associated type for a contract address
    /// @param contractAddress  Address of the contract we want to get the type for
    function getContractType(uint256 collection, address contractAddress) public view returns (uint256) {
        return contractToType[contractAddress];
    }

    /// @dev Associates a contract type with a library name
    /// @param contractType  Contract type
    /// @param libName       Library name
    function setLibraryNameForType(uint256 collection, uint256 contractType, bytes32 libName) public onlyOwnerOrStorage {
        contractTypeToLibraryName[contractType] = libName;
    }

    /// @dev Returns the library name for a given contract address
    /// @param contractAddress  Contract name
    /// @return                 Library name
    function getLibraryName(uint256 collection, address contractAddress) public view returns (bytes32) {
        uint256 contractType = contractToType[contractAddress];
        return contractTypeToLibraryName[contractType];
    }

    function getContractType(address contractAddress) public view returns (uint256) {
        return contractToType[contractAddress];
    }
}

interface IMatryxSystem {
    function createCollection(uint256 collection) external;
    function setCollection(uint256 collection) external;
    function getCurrentCollection() external view returns (uint256);
    function getAllCollections() external view returns (uint256[] memory);
    function addContract(uint256 collection, uint256 version, bytes32 name, address cAddress) external;
    function getContract(uint256 collection, uint256 version, bytes32 name) external view returns (address);
    function addCallTranslation(uint256 collection, uint256 version, bytes32 libName, bytes32 selector, ContractSystem.CallTranslationData calldata callTranslationData) external;
    function addCallTranslations(uint256 collection, uint256 version, bytes32 libName, bytes32[] calldata selectors, bytes32[] calldata librarySelectors, ContractSystem.CallTranslationData calldata callTranslationData) external;
    function getCallTranslation(uint256 collection, uint256 version, bytes32 identifier, bytes32 selector) external view returns (ContractSystem.CallTranslationData memory);
    function setContractType(uint256 collection, address cAddress, uint256 cType) external;
    function getContractType(uint256 collection, address cAddress) external view returns (uint256);
    function setLibraryNameForType(uint256 collection, uint256 contractType, bytes32 libName) external;
    function getLibraryNameForType(uint256 collection, uint256 contractType) external view returns (bytes32);
    function getContractType(address contractAddress) external view returns (uint256);
}

library LibSystem {
    enum ContractType { Unknown, Storage, DIDRegistry }
}
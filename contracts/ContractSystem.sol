pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract ContractSystem is Ownable() {
    
    mapping(bytes32=>ContractData) contracts;
    bytes32[] allContracts;
    mapping(address=>uint256) contractToType;
    mapping(uint256=>bytes32) contractTypeToLibraryName;

    // Stores information about a currently deployed contract or library
    struct ContractData {
        address location;
        uint256 currentVersion;
        mapping(uint256=>address) upgradeAgents;
        mapping(uint256=>mapping(bytes32=>CallTranslationData)) callTranslationData;
    }

    // Used to transform calls on a forwarder to its relevant library
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

    /// @dev Set a contract address for a contract by a given name
    /// @param version    Version of the contract
    /// @param name       Name of the contract we want to set an address for
    /// @param cAddress   Address of the contract
    function setContract(uint256 version, bytes32 name, address cAddress) public onlyOwner {
        require(hasCode(cAddress), "Invalid contract address");

        if (contracts[name].location == address(0)) {
            allContracts.push(name);
        }

        contracts[name].location = cAddress;
        contracts[name].currentVersion = version;
    }
    
    /// @dev Sets the address of the upgrade agent of a library's storage contract for a given version
    /// @param version    Version of the library to set the upgrade library for
    /// @param name       Name of the library to set the upgrade library for
    /// @param libAddress Upgrade agent library address
    function setUpgradeAgent(uint256 version, bytes32 name, address libAddress) public onlyOwner {
        require(contracts[name].location != address(0), "Invalid contract");
        require(hasCode(libAddress), "Invalid library address");
        contracts[name].upgradeAgents[version] = libAddress;    
    }

    /// @dev Returns the address of a contract given its name
    /// @param name       Name of the contract we want an address for
    /// @param version    Version of Platform to lookup the address on
    /// @return           Address of the contract
    function getContract(uint256 version, bytes32 name) public view returns (address) {
        address cAddress = contracts[name].location;
        require(hasCode(cAddress), "Invalid contract address");

        return cAddress;
    }

    /// @dev Register a library method for a library by its name
    /// @param version   Version of Platform for contract method association
    /// @param libName   Name of the contract to register a method for
    /// @param selector  Hash of the method signature to register to the contract (keccak256)
    /// @param callTranslationData    Calldata transformation information for library delegatecall
    function addCallTranslation(uint256 version, bytes32 libName, bytes32 selector, CallTranslationData memory callTranslationData) public onlyOwner {
        contracts[libName].callTranslationData[version][selector] = callTranslationData;
    }

    /// @dev Batch register library methods for a library by its name, that share the same injected and dynamic params
    /// @param version            Version of Platform for contract method association
    /// @param libName            Name of the contract we want an address for
    /// @param selectors          Hashes (keccak256) of the method signatures to register to the library 
    /// @param librarySelectors   Hashes (keccak256) of the library-specific method signatures to register to the contract
    /// @param callTranslationData         Calldata transformation information for library delegatecall
    function addCallTranslations(uint256 version, bytes32 libName, bytes32[] memory selectors, bytes32[] memory librarySelectors, CallTranslationData memory callTranslationData) public onlyOwner {
        require(selectors.length == librarySelectors.length, "List of selectors must match in length");

        for (uint256 i = 0; i < selectors.length; i++) {
            contracts[libName].callTranslationData[version][selectors[i]] = callTranslationData;
            contracts[libName].callTranslationData[version][selectors[i]].librarySelector = librarySelectors[i];
        }
    }

    /// @dev Gets calldata translation data given a library (name or type) and function selector
    /// @param version     Version of Platform for the method request
    /// @param libAddress  Address of the library to get the translation data for
    /// @param selector    Hash of the method signature to register to the contract (keccak256)
    /// @return            Calldata transformation information for library delegatecall
    function getCallTranslation(uint256 version, address libAddress, bytes32 selector) public view returns (CallTranslationData memory) {
        /* contract address identifier */
        bytes32 libraryName = contractTypeToLibraryName[contractToType[libAddress]];
        ContractData storage contractData = contracts[libraryName];

        // create the callTranslationData with the correct library address
        CallTranslationData memory translationData;
        bytes32 sel;
        assembly { sel := 0xd55ec697 }
        if(selector == sel) // 'upgrade()'
        {
            require(version != contractData.currentVersion);
            translationData.libraryLocation = contractData.upgradeAgents[version];
            translationData.librarySelector = selector;
            return translationData;
        }
        else
        {
            require(version == contractData.currentVersion);
        }

        translationData = contractData.callTranslationData[version][selector];
        translationData.libraryLocation = translationData.libraryLocation == address(0) ? contractData.location : translationData.libraryLocation;
        require(hasCode(translationData.libraryLocation), "Invalid contract address");
        
        return translationData;
    }

    /// @dev Associates a contract address with a type
    /// @param contractAddress  Address of the contract we want to set the type
    /// @param contractType     Type we want to associate the contract address with
    function setContractType(address contractAddress, uint256 contractType) public onlyOwnerOrStorage {
        require(hasCode(contractAddress), "Invalid contract address");
        contractToType[contractAddress] = contractType;
    }

    /// @dev Gets the associated type for a contract address
    /// @param contractAddress  Address of the contract we want to get the type for
    function getContractType(address contractAddress) public view returns (uint256) {
        return contractToType[contractAddress];
    }

    /// @dev Associates a contract type with a library name
    /// @param contractType  Contract type
    /// @param libName       Library name
    function setLibraryNameForType(uint256 contractType, bytes32 libName) public onlyOwnerOrStorage {
        contractTypeToLibraryName[contractType] = libName;
    }

    /// @dev Returns the library name for a given contract address
    /// @param contractAddress  Contract name
    /// @return                 Library name
    function getLibraryName(address contractAddress) public view returns (bytes32) {
        uint256 contractType = contractToType[contractAddress];
        return contractTypeToLibraryName[contractType];
    }

}

interface IMatryxSystem {
    function addContract(uint256 version, bytes32 name, address cAddress) external;
    function getContract(uint256 version, bytes32 name) external view returns (address);
    function addCallTranslation(uint256 version, bytes32 libName, bytes32 selector, ContractSystem.CallTranslationData calldata callTranslationData) external;
    function addCallTranslations(uint256 version, bytes32 libName, bytes32[] calldata selectors, bytes32[] calldata librarySelectors, ContractSystem.CallTranslationData calldata callTranslationData) external;
    function getCallTranslation(uint256 version, bytes32 identifier, bytes32 selector) external view returns (ContractSystem.CallTranslationData memory);
    function setContractType(address cAddress, uint256 cType) external;
    function getContractType(address cAddress) external view returns (uint256);
    function setLibraryNameForType(uint256 contractType, bytes32 libName) external;
    function getLibraryNameForType(uint256 contractType) external view returns (bytes32);
}

library LibSystem {
    enum ContractType { Unknown, Storage, DIDRegistry }
}
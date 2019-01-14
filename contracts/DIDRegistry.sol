pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./ContractSystem.sol";
import "./ContractStorage.sol";
import "./MessageForwarder.sol";

contract DIDRegistry is MessageForwarder {
    // mapping(bytes32 => LibDIDRegistry.DIDRegister) private didRegister;
    constructor (address _system, address storageAddress) MessageForwarder(_system, storageAddress) public {}
}

interface IDIDRegistry {
    function registerAttribute(bytes32 _did, LibDIDRegistry.ValueType _type, bytes32 _key, string calldata _value) external;
    function getUpdateAt(bytes32 _did) external view returns(uint);
    function getOwner(bytes32 _did) external view returns(address);

    function upgrade() external;
}

library LibDIDRegistry {
    using SafeMath for uint256;

    enum ValueType {
        DID,                // DID string e.g. 'did:op:xxx'
        DIDRef,             // hash of DID same as in parameter (bytes32 _did) in text 0x0123abc.. or 0123abc..
        URL,                // URL string e.g. 'http(s)://xx'
        DDO                 // DDO string in JSON e.g. '{ "id": "did:op:xxx"...
    }

    struct DIDRegister {
        address owner;
        uint updateAt;
    }

    event DIDAttributeRegistered(
        bytes32 indexed did,
        address indexed owner,
        bytes32 indexed key,
        string value,
        ValueType valueType,
        uint updatedAt
    );

    function registerAttribute(address self, address sender, uint256 didRegisterSlot, bytes32 _did, LibDIDRegistry.ValueType _type, bytes32 _key, string memory _value) public {
        address currentOwner;
        bytes32 s_location;
        assembly
        {
            mstore(0x00, _did)
            mstore(0x20, didRegisterSlot)
            s_location := keccak256(0, 0x40)
            currentOwner := sload(s_location)
        }
        require(currentOwner == address(0x0) || currentOwner == sender, 'Attributes must be registered by the DID owners.');

        assembly
        {
            sstore(s_location, sender)
            sstore(add(s_location, 1), number)
        }
        emit DIDAttributeRegistered(_did, sender, _key, _value, _type, block.number);
    }

    function getUpdateAt(address self, address sender, uint256 didRegisterSlot, bytes32 _did) public view returns(uint blockUpdated) {
        assembly
        {
            mstore(0x00, _did)
            mstore(0x20, didRegisterSlot)
            let s_location := keccak256(0, 0x40)
            
            blockUpdated := sload(add(s_location, 1))
        }
    }

    function getOwner(address self, address sender, uint256 didRegisterSlot, bytes32 _did) public view returns(address owner) {
        assembly
        {
            mstore(0x00, _did)
            mstore(0x20, didRegisterSlot)
            let s_location := keccak256(0, 0x40)
            
            owner := sload(s_location)
        }
    }
}

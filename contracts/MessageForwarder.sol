pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MessageForwarder {
    struct Info {
        uint256 collection;
        uint256 version;
        address system;
    }

    Info info;

    constructor(uint256 _collection, uint256 _version, address _system) public {
        info.collection = _collection;
        info.version = _version;
        info.system = _system;
    }

    /// @dev
    /// Gets the address of the current version of Platform and forwards the
    /// received calldata to this address. Injects msg.sender at the front so
    /// Platform and libraries can know calling address
    function () external {
        assembly {
            let ptr := mload(0x40)
            let offset := 0x100000000000000000000000000000000000000000000000000000000
            let cStorage := 0x43656e7472616c53746f72616765000000000000000000000000000000000000
            let collection := sload(info_slot)
            let version := sload(add(info_slot,1))
            let system := sload(add(info_slot, 2))

            // get CentralStorage address from ContractSystem
            mstore(ptr, mul(0x509f1089, offset))                                // getContract(uint256,uint256,bytes32)
            mstore(add(ptr, 0x04), collection)                            // arg 0 - collection this forwarder belongs to
            mstore(add(ptr, 0x24), version)                                     // arg 1 - version of this forwarder
            mstore(add(ptr, 0x44), cStorage)                                    // arg 2 - 'CentralStorage'
            let res := call(gas, system, 0, ptr, 0x64, 0, 0x20)                 // call ContractSystem.getContract
            if iszero(res) { revert(0, 0) }                                     // safety check
            cStorage := mload(0)                                                // load centralStorage address

            // forward call to CentralStorage, injecting sender, collection and version
            calldatacopy(ptr, 0, 0x04)                                          // copy signature
            mstore(add(ptr, 0x04), caller)                                      // inject msg.sender
            mstore(add(ptr, 0x24), collection)                                  // inject collection
            mstore(add(ptr, 0x44), version)                                     // inject version
            calldatacopy(add(ptr, 0x64), 0x04, sub(calldatasize, 0x04))         // copy calldata for forwarding
            res := call(gas, cStorage, 0, ptr, add(calldatasize, 0x60), 0, 0)   // forward method to CentralStorage
            if iszero(res) { revert(0, 0) }                                     // safety check

            // forward returndata to caller
            returndatacopy(ptr, 0, returndatasize)                              // copy returndata into ptr
            return(ptr, returndatasize)                                         // return returndata from forwarded call
        }
    }
}

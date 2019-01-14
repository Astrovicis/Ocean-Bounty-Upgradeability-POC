pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MessageForwarder {
    struct Info {
        address system;
        address storageAddress;
    }

    Info info;

    constructor(address _system, address _storageAddress) public {
        info.system = _system;
        info.storageAddress = _storageAddress;
    }

    /// @dev
    /// Gets the address of the current version of Platform and forwards the
    /// received calldata to this address. Injects msg.sender at the front so
    /// Platform and libraries can know calling address
    function () external {
        assembly {
            let ptr := mload(0x40)
            let offset := 0x100000000000000000000000000000000000000000000000000000000
            // needs to be specific to contract name (stored in info)
            let system := sload(info_slot)
            let cStorage := sload(add(info_slot, 1))


            mstore(ptr, mul(0x5a9b0b89, offset))                                // getInfo()        
            let res := call(gas, cStorage, 0, ptr, 0x04, ptr, 0x60)             // call contractStorage.getInfo
            if iszero(res) { revert(0,0) }                                      // safety check
            let version := mload(add(ptr, 0x20))                                // storage version

            // forward call to ContractStorage, injecting sender and version
            calldatacopy(ptr, 0, 0x04)                                          // copy selector
            mstore(add(ptr, 0x04), caller)                                      // inject msg.sender
            mstore(add(ptr, 0x24), version)                                     // inject version
            calldatacopy(add(ptr, 0x44), 0x04, sub(calldatasize, 0x04))         // copy calldata for forwarding

            res := call(gas, cStorage, 0, ptr, add(calldatasize, 0x40), 0, 0)   // forward method to ContractStorage
            if iszero(res) { revert(0, 0) }                                     // safety check

            // forward returndata to caller
            returndatacopy(ptr, 0, returndatasize)                              // copy returndata into ptr
            return(ptr, returndatasize)                                         // return returndata from forwarded call
        }
    }
}

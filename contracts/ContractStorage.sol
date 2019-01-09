pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./ContractSystem.sol";

contract ContractStorage {
    using SafeMath for uint256;

    struct Info {
        address system;
        address owner;
    }

    Info info;                              // slot 0

    constructor(address system) public {
        info.system = system;
        info.owner = msg.sender;
    }

    /// @dev
    /// 1) Uses msg.sender to ask MatryxSystem for the type of library this call should be forwarded to
    /// 2) Uses this library type to lookup (in its own storage) the name of the library
    /// 3) Uses this name to ask MatryxSystem for the address of the contract (under this platform's version)
    /// 4) Uses name and signature to ask MatryxSystem for the data necessary to modify the incoming calldata
    ///    so as to be appropriate for the associated library call
    /// 5) Makes a delegatecall to the library address given by MatryxSystem with the library-appropriate calldata
    function () external {
        assembly {
            // from MessageForwarder: selector, msg.sender, collection, version, ...calldata

            // constants
            let offset := 0x100000000000000000000000000000000000000000000000000000000
            let libCentralStorage := 0x4c696243656e7472616c53746f72616765000000000000000000000000000000

            let ptr := mload(0x40)                                              // scratch space for calldata
            let system := sload(info_slot)                                      // load info.system address

            mstore(0, mul(0xe11aa6a2, offset))                                  // getContractType(address)
            mstore(0x04, caller)                                                // arg 0 - contract
            let res := call(gas, system, 0, 0, 0x24, 0, 0x20)                   // call system.getContractType
            if iszero(res) { revert(0, 0) }                                     // safety check
            let contractType := mload(0)                                        // store type from response

            // get call translation data from system
            mstore(ptr, mul(0xfd912c66, offset))                                // getCallTranslation(uint256,uint256,bytes32,bytes32)
            calldatacopy(add(ptr, 0x04), 0x24, 0x20)                            // arg 0 - collection
            calldatacopy(add(ptr, 0x24), 0x44, 0x20)                            // arg 1 - version
            mstore(add(ptr, 0x44), caller)                                      // arg 2 - identifier
            calldatacopy(add(ptr, 0x64), 0, 0x04)                               // arg 3 - selector
            res := call(gas, system, 0, ptr, 0x84, 0, 0)                        // call system.getCallTranslation
            if iszero(res) { revert(0, 0) }                                     // safety check

            returndatacopy(ptr, 0, returndatasize)                              // copy translation data into ptr
            let ptr2 := add(ptr, mload(ptr))                                    // ptr2 is pointer to start of translation data

            let libAddress := mload(ptr2)                                        // copy library address from returndata
            let m_injParams := add(ptr2, mload(add(ptr2, 0x40)))                // mem loc injected params
            let injParams_len := mload(m_injParams)                             // num injected params
            m_injParams := add(m_injParams, 0x20)                               // first injected param

            let m_dynParams := add(ptr2, mload(add(ptr2, 0x60)))                // memory location of start of dynamic params
            let dynParams_len := mload(m_dynParams)                             // num dynamic params
            m_dynParams := add(m_dynParams, 0x20)                               // first dynamic param

            // forward calldata to library
            ptr := add(ptr, returndatasize)                                     // shift ptr to new scratch space
            mstore(ptr, mload(add(ptr2, 0x20)))                                 // forward call with modified selector

            ptr2 := add(ptr, 0x04)                                              // copy of ptr for keeping track of injected params

            mstore(ptr2, caller)                                                // inject msg.sender
            mstore(add(ptr2, 0x20), address)                                    // inject central storage address

            let cdOffset := 0x04                                                // calldata offset, after signature

            if gt(contractType, 1) {                                            // if call is from another contract
                calldatacopy(add(ptr2, 0x20), 0x04, 0x20)                       // overwrite injected CS address with address from forwarder
                cdOffset := add(cdOffset, 0x40)                                 // shift calldata offset for injected addresses
            }
            ptr2 := add(ptr2, 0x40)                                             // shift ptr2 to account for injected addresses

            for { let i := 0 } lt(i, injParams_len) { i := add(i, 1) } {        // loop through injected params and insert
                let injParam := mload(add(m_injParams, mul(i, 0x20)))           // get injected param slot
                mstore(ptr2, injParam)                                          // store injected params into next slot
                ptr2 := add(ptr2, 0x20)                                         // shift ptr2 by a word for each injected
            }

            calldatacopy(ptr2, cdOffset, sub(calldatasize, cdOffset))           // copy calldata after injected data storage

            for { let i := 0 } lt(i, dynParams_len) { i := add(i, 1) } {        // loop through params and update dynamic param locations
                let idx := mload(add(m_dynParams, mul(i, 0x20)))                // get dynParam index in parameters
                let loc := add(ptr2, mul(idx, 0x20))                            // get location in memory of dynParam
                mstore(loc, add(mload(loc), mul(add(injParams_len, 2), 0x20)))  // shift dynParam location by num injected
            }

            let size := add(0x04, sub(calldatasize, cdOffset))                  // calldatasize minus injected
            size := add(size, mul(add(injParams_len, 2), 0x20))                 // add size of injected
            res := delegatecall(gas, libAddress, ptr, size, 0, 0)               // delegatecall to library
            if iszero(res) { revert(0, 0) }                                     // safety check

            returndatacopy(ptr, 0, returndatasize)                              // copy return data into ptr for returning
            return(ptr, returndatasize)                                         // return forwarded call returndata
        }
    }

    /// @dev Gets Information about the Platform
    /// @return  Info Struct that contains system, version, token, and owner
    function getInfo() public view returns (ContractStorage.Info memory) {
        return info;
    }

    /// @dev Sets the owner of the platform
    /// @param newOwner  New owner address
    function setOwner(address newOwner) external {
        require(msg.sender == info.owner, "Must be Platform owner");
        require(newOwner != address(0));

        info.owner = newOwner;
    }

}

interface ICentralStorage {
    
}

library LibCentralStorage {
    
}
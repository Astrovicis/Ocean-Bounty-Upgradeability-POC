pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract LibDIDRegistry_UpgradeV1 {
    Info info;
    mapping(bytes32 => DIDRegister) private didRegister;

    struct Info {
        address system;
        uint256 version;
        address owner;
    }

    struct DIDRegister {
        address owner;
        uint updateAt;
    }
    
    function upgrade() public
    {
        didRegister[0x6469640000000000000000000000000000000000000000000000000000000000].owner = info.system;
    }
}
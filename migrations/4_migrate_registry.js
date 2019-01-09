const ContractSystem = artifacts.require('ContractSystem')
const DIDRegistry = artifacts.require('DIDRegistry')
const LibDIDRegistry = artifacts.require('LibDIDRegistry')

module.exports = function (deployer) {
  deployer.deploy(DIDRegistry, ContractSystem.address)
  deployer.deploy(LibDIDRegistry)
}

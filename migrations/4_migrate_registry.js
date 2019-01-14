const ContractSystem = artifacts.require('ContractSystem')
var ContractStorage = artifacts.require('ContractStorage')
const DIDRegistry = artifacts.require('DIDRegistry')
const LibDIDRegistry = artifacts.require('LibDIDRegistry')

module.exports = async function (deployer) {
  await deployer.deploy(DIDRegistry, ContractSystem.address, ContractStorage.address)
  await deployer.deploy(LibDIDRegistry)

  return LibDIDRegistry.deployed()
}
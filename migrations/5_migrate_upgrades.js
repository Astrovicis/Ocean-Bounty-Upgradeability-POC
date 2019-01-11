const LibDIDRegistry_UpgradeV1 = artifacts.require('LibDIDRegistry_UpgradeV1')

module.exports = async function (deployer) {
  await deployer.deploy(LibDIDRegistry_UpgradeV1)

  return LibDIDRegistry_UpgradeV1.deployed()
}
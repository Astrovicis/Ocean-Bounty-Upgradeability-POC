var ContractSystem = artifacts.require('ContractSystem')

module.exports = function(deployer) {
  deployer.deploy(ContractSystem)
}

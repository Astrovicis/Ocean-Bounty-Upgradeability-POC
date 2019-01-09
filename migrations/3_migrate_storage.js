var ContractSystem = artifacts.require('ContractSystem')
var ContractStorage = artifacts.require('ContractStorage')
var network = require('../truffle/network')

module.exports = function (deployer) {
  deployer.deploy(ContractStorage, ContractSystem.address)
}

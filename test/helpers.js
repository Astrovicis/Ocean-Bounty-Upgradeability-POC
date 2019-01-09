const fs = require('fs')
const { setup, genId, genAddress, getMinedTx, sleep, stringToBytes32, stringToBytes, Contract } = require('../truffle/utils')

Contract.logLevel = 1

module.exports = function (artifacts, web3) {

  const DIDRegistry = artifacts.require('DIDRegistery')
  const IDIDRegistry = artifacts.require('IDIDRegistry')

  async function init() {
    const contract = Contract
    let commands = fs.readFileSync('./setup', 'utf8').split('\n')
    for (let command of commands) {
      await eval(command)
    }

    // console.log("token:", network.tokenAddress)
    const data = await setup(artifacts, web3, 0, true)
    platform = data.platform
    token = data.token
    return { platform, token }
  }

  return {
    init
  }
}

const fs = require('fs')
const path = require('path')
const ethers = require('ethers')

const mnemonicHelper = require('mnemonichelper')
let accounts, privateKeys, mnemonic, provider, network

const setNetwork = id => {
    // if network already set, short circuit
    if (network === id) return

    network = id
    // ganache mnemonic below, ropsten mnemonic loaded from <project_root>/../keys/ropsten_mnemonic.txt
    mnemonic = "fix tired congress gold type flight access jeans payment echo chef host"

    if (network === 'ganache') {
        provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545')
    }
    else if (network === 'develop') {
        provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:9545')
    }
    else if (network == 'coverage') {
        provider = new ethers.providers.JsonRpcProvider('')
    }
    else if (['kovan', 'ropsten'].includes(network)) {
        provider = new ethers.providers.InfuraProvider(network, 'metamask')
        const mnemonicPath = path.join(__dirname, '../../keys/ropsten_mnemonic.txt')
        mnemonic = fs.readFileSync(mnemonicPath, 'utf8').trim().replace(/(\n|\r|\t|\u2028|\u2029|)/gm, '')
    }
    else console.log('bro check yo network')

    const accs = mnemonicHelper.getAccounts(mnemonic, 0, 10)
    accounts = accs.map(acc => acc[0])
    privateKeys = accs.map(acc => acc[1])
}

module.exports = {
    setNetwork,
    get network() { return network },
    get accounts() { return accounts },
    get privateKeys() { return privateKeys },
    get provider() { return provider },
    get mnemonic() { return mnemonic }
}

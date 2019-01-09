const DIDRegistry = artifacts.require('DIDRegistry')

const { init } = require('./helpers')(artifacts, web3)

contract('Registry Testing', function(accounts) {
  
  // TODO: Write test cases
  // it('Platform owner able to withdraw unallocated tokens from platform', async function() {
  //   let bb = await token.balanceOf(platform.address).then(fromWei)
  //   await platform.withdrawTokens(token.address)
  //   let ba = await token.balanceOf(platform.address).then(fromWei)
  //   assert.equal(bb - 10, ba, 'Unable to withdraw tokens')
  // })

})

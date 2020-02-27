const Contract = require('../../contracts');
const CommitReveal = require('./CommitReveal');

module.exports = async function() {
  try {
    var numberOfCommitments = await Contract.get.numberOfCommitment();
    var numberOfBet = await Contract.get.totalNumberOfBets('0x0000000000000000000000000000000000000000');
    if (numberOfCommitments - numberOfBet < 10) {
      throw new Error('Have not ready');
    }
  }
  catch (ex) {
    for (var i = 0; i < 20; i++) {
      var commitment = await CommitReveal.generateCommitment();
      console.log('Init game:');
      console.log(`   Commitment: ${commitment}`);
      var hash = await Contract.commit(commitment);
      var v = await Contract.get.checkTx(hash);
    }
  }
}
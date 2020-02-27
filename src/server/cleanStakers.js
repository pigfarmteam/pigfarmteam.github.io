const Contract = require('../contracts');

Contract.login({
  privateKey: process.env[`PK${process.env.PRIVATE_KEY}`] || process.env.PRIVATE_KEY
}, async (err, address) => {
  if (err) return callback && callback(err);

  console.log('Connect wallet:', address);
  var addresses = await Contract.get.stakers();
  while(true) {
    for (var i = 0; i < addresses.length; i++) {
      var needBreak = false;
      for (var j = i + 1; j < addresses.length; j++) {
        if (addresses[i].toLowerCase() == addresses[j].toLowerCase() && i != j) {
          var hash = await Contract.removeDuplicateStaker(i, j);
          await Contract.get.checkTx(hash);
          console.log(`Remove duplicate ${i}, ${j}: ${addresses[i]}`);
          needBreak = true;
          break;
        }
      }
      if (needBreak) break;
    }
    var newAddresses = await Contract.get.stakers();
    if (newAddresses.length == addresses.length) {
      break;
    }
    else {
      addresses = newAddresses;
    }
  }
  console.log('Done remove dup')
  addresses = await Contract.get.stakers();
  while(true) {
    for (var i = 0; i < addresses.length; i++) {
      var stake = await Contract.get.stake(addresses[i]);
      if (stake.amount == 0 && stake.profit == 0) {
        var hash = await Contract.removeStaker(i);
          await Contract.get.checkTx(hash);
          console.log(`Remove ${i}: ${addresses[i]}`);
          break;
      }
    }
    var newAddresses = await Contract.get.stakers();
    if (newAddresses.length == addresses.length) {
      break;
    }
    else {
      addresses = newAddresses;
    }
  }
  console.log('Done remove empty')
});
const Web3 = require('web3');

module.exports = {
  toTOMO(bigNum, isInt, noRound) {
    var v = Web3.utils.fromWei(bigNum.toString(), 'ether');
    v = parseFloat(v);
    if (isInt) {
      return Math.floor(v);
    }
    else if (noRound) {
      return v;
    }
    else {
        return Math.floor(v * 100) / 100
    }
  }
}
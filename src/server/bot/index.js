const Contract = require('../../contracts');
const CommitReveal = require('./CommitReveal');
const gameInit = require('./gameInit');
const db = require('../db');

var checkBetErrorTimer = 0;
var checkTakeProfitTimer = 0;
var reCheckBetTimer = 0;
var currentPrivateKey = process.env.PRIVATE_KEY;

var stop = false;
function betToString(bet) {
  return `${bet.index}: ${bet.player} | ${bet.round} | ${bet.number >= 10 ? bet.number : '0' + bet.number} | ${bet.isOver ? 'Over ' : 'Under'} | ${bet.amount}`;
}

function sleep(s) {
  return new Promise((done) => {
    setTimeout(() => {
      done()
    }, s)
  })
}

async function getBetForSettle(index) {
  try {
    var bet = await Contract.get.bet(index);
    return bet
  } catch (ex) {
    var msg = ex.toString();
    if (msg.indexOf('Invalid JSON RPC') >= 0) {
      console.error(ex.toString());
    }
  }

  return null;
}

async function settle(index, cb) {
  try {
    if (stop) return;

    var bet = await getBetForSettle(index);
    if (bet) {
      await db.set(`LAST_BET_SETTLE_${Contract.config.ADDRESS}`, index);
    }
    else {
      return settle(index, cb);
    }

    settle(index + 1, cb);

    if (!bet.isFinished) {
      setTimeout(async () => {
        try {
          await callSettle(bet, index);
        }
        catch (ex) {
          console.log('[Error] Settle error bet:', bet.index);
          await db.addBetError(bet.index);
          cb && cb(ex)
        }
      }, 30000);
    }
  }
  catch (ex) {
    cb && cb(ex);
  }
}

async function checkBetErrorAndTrySettleAgain(cb) {
  clearTimeout(checkBetErrorTimer);
  if (stop) return;
  
  try {
    var index = await db.getIndexOfBetError();
    if (!index) {
      checkBetErrorTimer = setTimeout(() => {
        checkBetErrorAndTrySettleAgain(cb)
      }, 30000);
      return ;
    }
    try {
      var bet = await getBetForSettle(index);
      if (bet.isFinished) {
        await db.removeBetError(index);
      }
      else {
        console.log('TRY SETTLE AGAIN BET:', index);
        await callSettle(bet);
        await db.removeBetError(index);
      }
    }
    catch (ex) {
      console.log('[Error] Try settle bet again:', index);
      cb && cb(ex)
    }
    checkBetErrorTimer = setTimeout(() => {
      checkBetErrorAndTrySettleAgain(cb)
    }, 2000);
  }
  catch (ex) {
    cb && cb(ex);
    checkBetErrorTimer = setTimeout(() => {
      checkBetErrorAndTrySettleAgain(cb)
    }, 30000);
  }
}

async function reCheckBetAndTrySettleAgain(cb) {
  clearTimeout(reCheckBetTimer);
  if (stop) return;
  
  try {
    var numberOfBet = await Contract.get.totalNumberOfBets('0x0000000000000000000000000000000000000000');
    for (var i = numberOfBet - 120; i < numberOfBet - 20; i++) {
      try {
        var bet = await getBetForSettle(i);
        if (!bet.isFinished) {
          console.log('TRY SETTLE AGAIN BET:', i);
          await callSettle(bet);
        }
      }
      catch (ex) {
        console.log('[Error] Try settle bet again:', i);
        cb && cb(ex)
      }
    }
    
    reCheckBetTimer = setTimeout(() => {
      reCheckBetAndTrySettleAgain(cb)
    }, 30000);
  }
  catch (ex) {
    cb && cb(ex);
    reCheckBetTimer = setTimeout(() => {
      reCheckBetAndTrySettleAgain(cb)
    }, 30000);
  }
}

async function checkTakeProfitAndSettleLeaderBoard(cb) {
  clearTimeout(checkTakeProfitTimer);
  if (stop) return;

  try {
    var block = await Contract.get.lastBlock();
    var blockNumber = parseInt(block.number);

    var currentRound;
    var takeProfitAtBlock;

    var [currentRound, takeProfitAtBlock] = await Promise.all([
      Contract.get.roundLeaderBoard(0, true),
      Contract.get.takeProfitAtBlock()
    ]);

    if (blockNumber > currentRound || blockNumber > takeProfitAtBlock) {
      //console.log('Start take profit');
      var hash = await Contract.finishLeaderBoard();
      await Contract.get.checkTx(hash);
      hash = await Contract.takeProfit(),
      await Contract.get.checkTx(hash);
      console.log('[End] Finish take profit');
    }
    checkTakeProfitTimer = setTimeout(() => {
      checkTakeProfitAndSettleLeaderBoard(cb)
    }, 5000);
  }
  catch (ex) {
    cb && cb(ex);
    checkTakeProfitTimer = setTimeout(() => {
      checkTakeProfitAndSettleLeaderBoard(cb)
    }, 5000);
  }
}


async function callSettle(bet) {
  if (bet) {
    var secret = await CommitReveal.getSecretForBet(bet);
    var commitment = await CommitReveal.generateCommitment();
    var hash = await Contract.settleBet(bet.index, secret, commitment);
    await sleep(3000);
    await Contract.get.checkTx(hash);
    bet = await Contract.get.bet(bet.index)
    if (!bet.isFinished) {
      throw Error(`${bet.index} - Still not finish`)
    }
    console.log(betToString(bet), ' > ', hash);
  }
}

module.exports = {
  start: (shouldChangePrivateKey, callback) => {
    stop = false;
    if (shouldChangePrivateKey && !isNaN(parseInt(currentPrivateKey))) {
      var nextPK = parseInt(currentPrivateKey) + 1;
      nextPK = (nextPK % 2) + 1;
      currentPrivateKey = process.env[`PK${nextPK}`]
    }
    Contract.login({
      privateKey: process.env[`PK${currentPrivateKey}`] || currentPrivateKey
    }, async (err, address) => {
      if (err) return callback && callback(err);

      console.log('Connect wallet:', address);
      try {
        await gameInit();
        var betIndex = 1;
        try {
          betIndex = await db.get(`LAST_BET_SETTLE_${Contract.config.ADDRESS}`);
          betIndex = parseInt(process.env.SETTLE_BET_INDEX || 0) || parseInt(betIndex);
          betIndex = betIndex - 20
          betIndex = betIndex > 0 ? betIndex : 0
        }
        catch (ex) {
        }
        console.log('Settle from bet:', betIndex);
        await db.set(`LAST_BET_SETTLE_${Contract.config.ADDRESS}`, betIndex);
        settle(betIndex, callback);
        clearTimeout(checkTakeProfitTimer);
        clearTimeout(checkBetErrorTimer);
        clearTimeout(reCheckBetTimer);
        checkBetErrorTimer = setTimeout(() => {
          checkBetErrorAndTrySettleAgain(callback);
        }, 30000);
        reCheckBetTimer = setTimeout(() => {
          reCheckBetAndTrySettleAgain(callback);
        }, 30000)
        checkTakeProfitTimer = setTimeout(() => {
          checkTakeProfitAndSettleLeaderBoard(callback);
        }, 10000);
        
        setTimeout(() => {
          callback && callback('restart')
        }, 10 * 60 * 1000)
      }
      catch (ex) {
        console.error('server > bot > index > 80 >', ex.toString());
        cb && cb(ex);
      }
    });
  },
  stop() {
    clearTimeout(checkBetErrorTimer);
    clearTimeout(checkTakeProfitTimer);
    stop = true;
  }
}

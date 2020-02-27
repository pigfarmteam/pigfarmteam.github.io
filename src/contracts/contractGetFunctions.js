const Web3 = require('web3');
const CONTRACT_CONFIG = require('./contractConfig');
const utils = require('../utils');


var listener = {};
var LAST_BLOCK = null;
var listenLastBlockTimeout;

var socketEnd = () => {
  // if (typeof window !== 'undefined') {
  //   var mobileAndTabletcheck = function() {
  //     var check = false;
  //     (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
  //     return check;
  //   };
  //   if (mobileAndTabletcheck()) {
  //     if (sessionStorage.disconnectedAt) {
  //       if (new Date().getTime() - parseInt(sessionStorage.disconnectedAt) > 60000) {
  //         delete sessionStorage.disconnectedAt;
  //         window.location.reload();
  //         return;
  //       }
  //     }
  //     else {
  //       sessionStorage.disconnectedAt = new Date().getTime().toString();
  //     }
  //   }
  // }
  clearTimeout(listenLastBlockTimeout);
  listenNewBlock(0);
  restartReadWeb3();
}

var socketError = () => {
  restartReadWeb3();
}

var sockerConnect = () => {
  listener['SocketConnect'] = listener['SocketConnect'] || [];
  listener['SocketConnect'].forEach(f => f.func({}));
}

function setUpProvider(provider) {
  provider.on('connect', () => sockerConnect())
  provider.on('error', e => socketError(e));
  provider.on('end', e => socketEnd(e));
}

function restartReadWeb3() {
  var provider = new Web3.providers.WebsocketProvider(CONTRACT_CONFIG.RPC_READ_SOCKET);
  setUpProvider(provider);
  web3Socket.setProvider(provider);
  LuckyContractSocket.events.allEvents().on('data', (evt) => processEvent(evt))
}

var provider = new Web3.providers.WebsocketProvider(CONTRACT_CONFIG.RPC_READ_SOCKET);
setUpProvider(provider);

var web3Socket = new Web3(provider);
var web3 = new Web3(CONTRACT_CONFIG.RPC_READ);
var LuckyContract = new web3.eth.Contract(CONTRACT_CONFIG.ABI, CONTRACT_CONFIG.ADDRESS);
var LuckyContractSocket = new web3Socket.eth.Contract(CONTRACT_CONFIG.ABI, CONTRACT_CONFIG.ADDRESS);
LuckyContractSocket.events.allEvents().on('data', (evt) => processEvent(evt))

function processEvent(e) {
  listener[e.event] = listener[e.event] || [];
  listener[e.event].forEach(f => {
    try {
      f.func(e.returnValues)
    }
    catch (ex) {
      console.log(ex);
    }
  });
}

var checkTransactionCount = {}
function checkTransactionReceipt(tx, cb) {
  checkTransactionCount[tx] = checkTransactionCount[tx] || new Date().getTime();
  if (new Date().getTime() - checkTransactionCount[tx] > 20000) {
    return cb(new Error('Timeout'));
  }
  web3.eth.getTransactionReceipt(tx, (err, v) => {
    if (err) cb(err)
    else if (v) cb(false, v);
    else if (!LAST_BLOCK) setTimeout(() => checkTransactionReceipt(tx, cb), 500);
    else {
      var timestamp = LAST_BLOCK.timestamp * 1000;
      var timeNextBlock = timestamp + 2500;
      var timeNow = new Date().getTime();
      var timeout = timeNextBlock - timeNow;
      if (timeout > 0) setTimeout(() => checkTransactionReceipt(tx, cb), timeout);
      else setTimeout(() => checkTransactionReceipt(tx, cb), 500);
    }
  });
}

async function listenNewBlock(blockNumber) {
  var block = await web3.eth.getBlock('latest');
  if (block.number > blockNumber) {
    LAST_BLOCK = block;
    processEvent({
      event: 'NEW_BLOCK',
      returnValues: block
    });
  }

  var timestamp = block.timestamp * 1000;
  var timeNextBlock = timestamp + 2500;
  var timeNow = new Date().getTime();
  var timeout = timeNextBlock - timeNow;
  if (timeout > 0) listenLastBlockTimeout = setTimeout(() => listenNewBlock(block.number), timeout);
  else listenLastBlockTimeout = setTimeout(() => listenNewBlock(block.number), 1000);
}

listenNewBlock(0);

module.exports = {
  Contract: LuckyContractSocket,
  onListenEvent: function(method, func, keyFunc) {
    listener[method] = listener[method] || [];
    if (keyFunc) {
      var e = listener[method].find(e => e.keyFunc == keyFunc);
      if (e) {
        e.func = func;
      }
      else {
        listener[method].push({
          keyFunc: keyFunc,
          func: func
        });
      }
    }
    else {
      listener[method].push({
        keyFunc: listener[method].length,
        func: func
      });
    }
  },
  offListenEvent: function(method, func) {
    var keyFunc = typeof func === 'function' ? null : func;
    listener[method] = listener[method] || [];
    listener[method] = listener[method].filter(e => keyFunc ? e.keyFunc != keyFunc : e.func != func);
  },
  checkTx: function(hash) {
    return new Promise((resolve, reject) => {
      checkTransactionReceipt(hash, (error, tx) => {
        error ? reject(error) :
        (tx.status ? resolve(tx) : reject(new Error('Reverted the transaction')));
      });
    })
  },
  lastBlock: function (fromCache) {
    return fromCache ? LAST_BLOCK : web3.eth.getBlock('latest');
  },
  contractAddress() {
    return CONTRACT_CONFIG.ADDRESS;
  },
  balance: function (address) {
    return web3.eth.getBalance(address);
  },
  getMaxStakersInPool: function () {
    return LuckyContract
      .methods
      .MAX_STAKER_IN_POOL()
      .call()
      .then(v => parseInt(v));
  },
  houseEdge: function () {
    return LuckyContract.methods
      .HOUSE_EDGE()
      .call()
      .then(v => parseInt(v));
  },
  gameBalance: function() {
    return LuckyContract.methods
      .balanceForGame(0)
      .call()
      .then(v => utils.toTOMO(v))
  },
  totalNumberOfBets: function (add) {
    return LuckyContract
      .methods
      .totalNumberOfBets(add)
      .call()
      .then(n => parseInt(n));
  },
  numberOfBets: function(round) {
    return LuckyContract
      .methods
      .numberOfBets(round)
      .call()
      .then(n => parseInt(n));
  },
  numberOfRounds: function () {
    return LuckyContract
      .methods
      .numberOfRounds()
      .call()
  },
  bet: function (index) {
    return LuckyContract
      .methods
      .bets(index)
      .call()
      .then(bet => ({
        index: parseInt(bet.index),
        amount: utils.toTOMO(bet.amount),
        number: parseInt(bet.number),
        isOver: bet.isOver,
        round: parseInt(bet.round),
        isFinished: bet.isFinished,
        luckyNumber: parseInt(bet.luckyNumber),
        player: bet.player.toLowerCase()
      }))
  },
  betOf: function(address, index) {
    return LuckyContract
      .methods
      .betsOf(address, index)
      .call()
      .then(i => {
        i = parseInt(i);
        return LuckyContract
          .methods
          .bets(i)
          .call()
          .then(bet => ({
            index: parseInt(bet.index),
            amount: utils.toTOMO(bet.amount),
            number: parseInt(bet.number),
            isOver: bet.isOver,
            round: parseInt(bet.round),
            isFinished: bet.isFinished,
            luckyNumber: parseInt(bet.luckyNumber),
            player: bet.player.toLowerCase()
          }));
      })
  },
  lastBet: function (address) {
    return LuckyContract
      .methods
      .getLastBetIndex(address)
      .call()
      .then(index => {
        return LuckyContract
          .methods
          .bets(index)
          .call()
          .then(bet => ({
            index: parseInt(bet.index),
            amount: utils.toTOMO(bet.amount),
            number: parseInt(bet.number),
            isOver: bet.isOver,
            round: parseInt(bet.round),
            isFinished: bet.isFinished,
            luckyNumber: parseInt(bet.luckyNumber),
            player: bet.player.toLowerCase()
          }));
      })
  },
  luckyNumber: function (round) {
    return LuckyContract
      .methods
      .generateRandomNumber(round)
      .call()
      .then(n => parseInt(n))
  },
  stakersInPool: function () {
    return LuckyContract
      .methods
      .getStakersInPool()
      .call()
  },
  stakers: function () {
    return LuckyContract
      .methods
      .getStakers()
      .call()
  },
  stake: function (address) {
    return LuckyContract
      .methods
      .stakes(address)
      .call()
  },
  betRange: function(number, isOver) {
    return LuckyContract
      .methods
      .betRange(number, isOver, 0)
      .call()
      .then(v => {
        var result = {
          min: utils.toTOMO(v.min),
          max: utils.toTOMO(v.max)
        }
        result.max = result.max > 500 ? 500 : result.max;
        result.min = result.min;
        result.max = result.max > 10 ? Math.floor(result.max) : result.max;
        return result;
      })
  },
  currentLeaderBoard: function() {
    return LuckyContract
      .methods
      .getCurrentLeaderBoard()
      .call();
  },
  roundLeaderBoard: function(index, isFromTail) {
    return LuckyContract
      .methods
      .getRoundLeaderBoard(index, isFromTail)
      .call()
      .then(v => parseInt(v));
  },
  leaderBoardWinner: function(round, address) {
    return LuckyContract
      .methods
      .leaderBoardWinners(round, address)
      .call();
  },
  leaderBoardAddress: function(round, index) {
    return LuckyContract
      .methods
      .leaderBoards(round, index)
      .call();
  },
  totalBetOfPlayer: function(round, address) {
    return LuckyContract
      .methods
      .totalBetOfPlayers(round, address)
      .call();
  },
  takeProfitAtBlock: function() {
    return LuckyContract
      .methods
      .takeProfitAtBlock()
      .call()
      .then(n => parseInt(n));
  },
  totalPrize: function() {
    return LuckyContract
      .methods
      .totalPrize()
      .call()
      .then(v => utils.toTOMO(v));
  },
  getMinAmountForJoin: function(address) {
    return LuckyContract
      .methods
      .getMinAmountForJoin(address)
      .call()
      .then(n => utils.toTOMO(n));
  },
  commitment: function(index) {
    return LuckyContract
      .methods
      .commitments(index)
      .call()
  },
  indexOfDrawnBet: function() {
    return LuckyContract
      .methods
      .indexOfDrawnBet()
      .call()
      .then(n => parseInt(n));
  },
  numberOfCommitment: function() {
    return LuckyContract
      .methods
      .numberOfCommitment()
      .call()
      .then(n => parseInt(n));
  },
  getPrizePerBetLevel: function() {
    return LuckyContract
      .methods
      .PRIZE_PER_BET_LEVEL()
      .call()
      .then(n => parseInt(n));
  },
  isLogon: function(add) {
    return LuckyContract
      .methods
      .accounts(add)
      .call()
      .then(n => parseInt(n) > 0);
  },
  referralReward: function(add) {
    var ReferralContract = new web3.eth.Contract(CONTRACT_CONFIG.ABI_REFERRAL, CONTRACT_CONFIG.REFERRAL_ADDRESS)
    return ReferralContract.methods
      .rewards(add)
      .call()
      .then(n => utils.toTOMO(n, false, true));
  },
  totalBetOf: function(add) {
    return LuckyContract
      .methods
      .amountOf(add)
      .call()
      .then(v => ({
        totalBet: utils.toTOMO(v.totalBet),
        totalPayout: utils.toTOMO(v.totalPayout)
      }));
  },
}
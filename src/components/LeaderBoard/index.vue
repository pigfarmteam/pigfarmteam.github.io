<template>
  <div class="fs15">
    <div v-if="lastWinners.length">
      <h2 class="yellow" style="margin-top: 0">
        <img src="./trophy.svg" width="25px"/>&nbsp;&nbsp;Winners of Last Round&nbsp;&nbsp;<img src="./trophy.svg" width="25px"/>
      </h2>
      <div v-for="(e, i) in lastWinners" :key="e.address" style="text-align: left;">
        <!-- <div class="mt-15">Earning <span class="fs30">{{e.prize}}</span> <span class="fs15">TOMO</span></div> -->
        <div class="mt10">
          <!-- <img v-if="i==0" src="./gold-medal.png" width="20px" class="ml10"/>&nbsp;&nbsp; -->
          <span v-if="i==0" style="font-size: 25px; line-height: 0.1;">🏆</span>
          <span v-if="i==1" style="font-size: 25px; line-height: 0.1;">🥈</span>
          <span v-if="i==2" style="font-size: 25px; line-height: 0.1;">🥉</span>
          <span class="yellow">{{e.prize}} TOMO</span> &nbsp;&nbsp;{{e.address}}
          <!-- 🏆🥇🥈🥉 -->
        </div>
      </div>
      <div class="line"></div>
    </div>
    <div class="fs25" style="background: #009688">
      <div class="fs20">Prize for this Round: <span class="fs30 yellow">{{currentPrize}} <span class="fs15">TOMO</span></span></div>
      <div class="countdownLead">
        Finish at block <b>{{this.round}}</b><br/>
        Count Down: {{countDownBlock}} blocks ~ {{countDownTime}}
      </div>
    </div>
    <table width="100%" class="mt10">
      <thead>
        <tr class="fs12">
          <th width="30px">#</th>
          <th>PLAYER</th>
          <th>TOTAL BET</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(e, i) in players" :key="e.address + i">
          <td>
            {{i + 1}}
          </td>
          <td style="word-break: break-all; padding-right:10px;">
            {{e.address}}
          </td>
          <td style="color: #f0c22a;">
            {{e.amount}}
          </td>
        </tr>
      </tbody>
    </table>
    <div class="text-right pr15 pl15 mt30">
      <button class="btn primary" @click="store.isShowDonateForPrizePoolModal = true">
        Donate for Leader Board Prize
      </button>
    </div>
  </div>
</template>

<script>

import Contract from '../../contracts';
import utils from '../../utils';
import _store from '../../store';

export default {
  data() {
    return {
      round: 0,
      lastRound: 0,
      lastWinners: [],
      currentBlock: 0,
      time: '',
      players: [],
      store: _store
    }
  },
  async created() {
    this.getLastLeaderBoard();
    this.updateLeader();
    this.currentBlock = (await Contract.get.lastBlock(true) || {}).number;
    Contract.get.onListenEvent('NEW_BLOCK', e => this.updateLastBlock(e), 'LEADER_BOARD_NEW_BLOCK');
  },
  destroyed() {
    clearTimeout(this.timeoutUpdate);
    clearTimeout(this.timerCountdown);
    Contract.get.offListenEvent('NEW_BLOCK', 'LEADER_BOARD_NEW_BLOCK');
  },
  computed: {
    countDownBlock() {
      var n = this.round - this.currentBlock;
      return n > 0 ? n : 0;
    },
    countDownTime() {
      var h = Math.floor(this.time / 3600);
      var m = Math.floor(this.time % 3600 / 60);
      var s = Math.floor(this.time % 3600 % 60);
      h = h < 10 ? `0${h}` : h;
      m = m < 10 ? `0${m}` : m;
      s = s < 10 ? `0${s}` : s;
      return `${h}:${m}:${s}`;
    },
    currentPrize() {
      return this.store.currentPrize;
    }
  },
  methods: {
    countDown() {
      clearInterval(this.timerCountdown);
      var n = this.round - this.currentBlock;
      n = n >= 0 ? n : 0;
      this.time = n * 2;
      this.timerCountdown = setInterval(() => {
        this.time -= 1;
        this.time = this.time >= 0 ? this.time : 0;
      }, 1000);
    },
    updateLastBlock(lastBlock) {
      this.currentBlock = parseInt(lastBlock.number);
    },
    async updateLeader() {
      this.store.currentPrize = await Contract.get.totalPrize();
      var data = await Contract.get.currentLeaderBoard();
      var lastBlock = await Contract.get.lastBlock();
      this.currentBlock = parseInt(lastBlock.number);
      this.round = parseInt(data.currentRound);

      this.countDown();
      var addresses = data.players;

      for (var i = 0; i < addresses.length; i++) {
        var address = addresses[i];
        address = address.toLowerCase();
        var amount = await Contract.get.totalBetOfPlayer(this.round, address);
        var player = this.players.find(p => p.address == address);
        if (player) {
          player.amount = utils.toTOMO(amount, true);
        }
        else {
          this.players.push({
            address: address,
            amount: utils.toTOMO(amount, true)
          });
        }
        this.players = this.players.sort((a, b) => b.amount - a.amount);
      }

      this.players = this.players.slice(0, 10);

      this.timeoutUpdate = setTimeout(() => this.updateLeader(), 15000);
    },
    async getLastLeaderBoard() {
      try {
        var round = await Contract.get.roundLeaderBoard(1, true);
        var cacheWinners = JSON.parse(localStorage.winners || '{}');
        var winners = [];
        if (cacheWinners[round]) {
          winners = cacheWinners[round];
          if (winners.length > 0) {
            this.lastRound = round;
            this.lastWinners = winners;
          }
        }
        else {
          for (var i = 0; i < 30; i++) {
            try {
              var address = await Contract.get.leaderBoardAddress(round, i);
              var prize = await Contract.get.leaderBoardWinner(round, address);
              if (prize > 0) {
                winners.push({
                  address: address,
                  prize: utils.toTOMO(prize)
                });
              }
            }
            catch (ex) {
              break;
            }
          }
          if (winners.length > 0) {
            this.lastWinners = winners.sort((a, b) => parseFloat(b.prize) - parseFloat(a.prize));
            this.lastRound = round;
            cacheWinners[round] = winners;
            localStorage.winners = JSON.stringify(cacheWinners);
          }
        }
      }
      catch (ex) {
      }
    }
  }
}
</script>
<style>
.line {
  height: 1px;
  width: 100%;
  background: rgba(255, 255, 255, 0.2);
  margin: 10px 0;
}
.countdownLead {
  font-size: 13px;
  opacity: 0.7;
  font-family: monospace;
  padding-bottom: 10px;
}
table {
  border-spacing: 0
}
table thead tr th {
  padding-top: 4px;
  padding-bottom: 10px;
}
table tbody tr td {
  padding-top: 4px;
  padding-bottom: 4px;
}
table tbody tr:nth-of-type(odd) {
  background: rgba(256, 256, 256, 0.06)
}
</style>

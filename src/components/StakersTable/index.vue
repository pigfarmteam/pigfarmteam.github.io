<template>
  <div class="fs15">
    <div class="text-center prize" style="background: #009688">
      Total Prize: <span style="color: #ecb83a" class="fs25">{{gameBalance}} TOMO</span>
    </div>
    <table width="100%" class="mt20">
      <thead>
        <tr class="fs12">
          <th>STAKER</th>
          <th width="100px">AMOUNT</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="e in stakers" :key="e.address">
          <td style="word-break: break-all; padding-right:10px;">
            {{e.address}}
          </td>
          <td class="yellow">
            {{e.amount}}&nbsp;<span class="fs12">TOMO</span>
          </td>
        </tr>
      </tbody>
    </table>
    <div v-if="!isLoading && !isInPool && stake > 0" class="staker-alert">
      <div class="mt10 red fs20">You are out of pool</div>
      <div class="fs15">Your stake is not enough, stake {{minAmount}} TOMO to jump into pool</div>
    </div>
    <div class="text-right pr15 pl15 mt30">
      <button class="btn primary" @click="store.isShowJoinStakePoolModal = true">
        {{stake > 0 ? "Stake more to be rich": "Join stake pool to take revenue"}}
      </button>
      <button v-if="stake > 0" class="btn secondary white mt10" @click="store.isShowManageStakeModal = true">
        Manage Your Stake
      </button>
    </div>
  </div>
</template>

<script>
import _store from '../../store';
import Contract from '../../contracts';
import utils from '../../utils';

export default {
  data() {
    return {
      store: _store,
      gameBalance: 0,
      stakers: [],
      stake: 0,
      isInPool: false,
      minAmount: 0,
      isLoading: true,
    }
  },
  created() {
    this.getListStakers();
    this.subcribeNewStake();
    this.subcribeQuitPool();
  },
  destroyed() {
    Contract.get.offListenEvent('NewStake', 'stakeTable');
    Contract.get.offListenEvent('QuitPool', 'stakeTable');
  },
  methods: {
    subcribeNewStake() {
      Contract.get.onListenEvent('NewStake', () => this.getListStakers(), 'stakeTable');
    },
    subcribeQuitPool() {
      Contract.get.onListenEvent('QuitPool', () => this.getListStakers(), 'stakeTable');
    },
    async getListStakers() {
      this.isLoading = true;
      if (this.store.address) {
        Contract.get.getMinAmountForJoin(this.store.address)
        .then(n => this.minAmount = n);

        Contract.get.stake(this.store.address)
        .then(stake => {
          this.isInPool = stake.isInPool;
          this.stake = utils.toTOMO(stake.amount)
          this.isLoading = false;
        });
      }

      this.gameBalance = await Contract.get.gameBalance();
      this.gameBalance = Math.floor(this.gameBalance);

      var addresses = await Contract.get.stakersInPool();
      addresses = addresses.map(e => e.toLowerCase());
      for (var i = 0; i < addresses.length; i++) {
        var address = addresses[i];
        var stake = await Contract.get.stake(address)
        stake.address = address;
        stake.amount = utils.toTOMO(stake.amount, true);
        stake.totalStake = utils.toTOMO(stake.totalStake);
        var _stake = this.stakers.find(e => e.address == address);
        if (_stake) {
          _stake.totalStake = stake.totalStake;
          _stake.amount = stake.amount;
        }
        else {
          this.stakers.push(stake);
        }
        this.stakers = this.stakers.sort((a, b) => b.amount - a.amount);
      }
      this.stakers = this.stakers.filter(e => addresses.indexOf(e.address) >= 0).filter(e => parseFloat(e.amount) >= 1);
    }
  }
}
</script>

<style scoped>
.staker-table-joinbuton {
  color: #00a8ec;
  text-decoration: underline;
  cursor: pointer;
}

.staker-prize {
  font-size: 20px;
}

.staker-alert {
  background: #ffc107;
  padding: 1px 0 9px 0;
  margin-top: 20px;
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

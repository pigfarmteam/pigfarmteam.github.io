<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container" style="margin-top: 100px;">
      <button class="modal-close-btn" @click="() => store.isShowManageStakeModal = false" />
      <div class="modal-title">
        Manage Stake
      </div>
      <div class="gray">Total Stake:</div>
      <div class="fs30 mt-10">{{totalStake}}<span class="fs15">&nbsp;TOMO</span></div>
      <div v-if="totalStake > stake">
        <div class="gray mt10">Remaning Stake:</div>
        <div class="fs30 mt-10">{{stake}}<span class="fs15">&nbsp;TOMO</span></div>
        <div class="remaining-stake red">(remaning stake is less than total stake because the host is losing)</div>
      </div>

      <div v-if="isInPool" class="gray mt10">Revenue:</div>
      <div v-if="isInPool" class="fs40 mt-15 green">{{revenue }}<span class="fs25">&nbsp;TOMO</span></div>

      <div v-if="isInPool" class="countdownLead">
        Distribute Profit at Block: <b>{{this.takeProfitAtBlock}}</b><br/>
        Count Down: {{countDownBlock}} blocks ~ {{countDownTime}}
      </div>

      <div v-if="!isInPool && stake" class="mt10 red fs20">You are out of pool</div>
      <div v-if="!isInPool && stake" class="fs15">Your stake is not enough, stake {{minAmount}} TOMO to jump into pool</div>
      <button class="btn primary mt10" @click="stakeMore">STAKE MORE</button>
      <button class="btn secondary mt10" @click="withdraw">WITHDRAW</button>
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
      stake: 0,
      totalStake: 0,
      isInPool: false,
      minAmount: 0,
      revenue: 0,
      currentBlock: 0,
      takeProfitAtBlock: 0,
      time: 0,
    }
  },
  async created() {
    this.minAmount = await Contract.get.getMinAmountForJoin(this.store.address);

    Contract.get.stake(this.store.address)
    .then(stake => {
      this.isInPool = stake.isInPool;
      this.stake = utils.toTOMO(stake.amount);
      this.totalStake = utils.toTOMO(stake.totalStake);
      this.revenue = utils.toTOMO(stake.profit)
    });
    this.takeProfitAtBlock = await Contract.get.takeProfitAtBlock();
    this.currentBlock = (await Contract.get.lastBlock(true) || {}).number;
    Contract.get.onListenEvent('NEW_BLOCK', e => this.updateLastBlock(e), 'MANAGE_STAKE_NEW_BLOCK');
    this.countDown();
  },
  destroyed() {
    clearTimeout(this.timeoutUpdate);
    clearTimeout(this.timerCountdown);
    Contract.get.offListenEvent('NEW_BLOCK', 'MANAGE_STAKE_NEW_BLOCK');
  },
  computed: {
    countDownBlock() {
      var n = this.takeProfitAtBlock - this.currentBlock;
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
    }
  },
  methods: {
    stakeMore() {
      this.store.isShowJoinStakePoolModal = true;
      this.store.isShowManageStakeModal = false;
    },
    withdraw() {
      this.store.isShowManageStakeModal = false;
      this.store.isShowWithdrawModal = true;
    },
    countDown() {
      clearInterval(this.timerCountdown);
      var n = this.takeProfitAtBlock - this.currentBlock;
      n = n >= 0 ? n : 0;
      this.time = n * 2;
      this.timerCountdown = setInterval(() => {
        this.time -= 1;
        this.time = this.time >= 0 ? this.time : 0;
      }, 1000);
    },
    updateLastBlock(lastBlock) {
      this.currentBlock = parseInt(lastBlock.number);
    }
  }
}
</script>

<style scoped>
.join-qr {
  width: 130px;
  height: 130px;
  margin: auto;
}

.join-qr canvas {
    height: 130px;
    width: 130px;
}

.join-qr-description {
  font-family: monospace;
  line-height: 1;
  margin-top: 10px;
  font-size: 15px;
  color: gray;
  text-align: center;
}
.remaining-stake {
  font-family: sans-serif;
  font-size: 12px !important;
  margin-top: -10px;
  margin-bottom: 15px;
}
.countdownLead {
  font-size: 13px;
  opacity: 0.7;
  font-family: monospace;
  padding-bottom: 10px;
}
</style>

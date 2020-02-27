<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container" style="margin-top: 100px;">
      <button class="modal-close-btn" @click="() => store.isShowJoinStakePoolModal = false" />
      <div class="modal-title">
        Join Stake Pool
      </div>
      <div v-if="!msg">
        <div v-if="stake > 0">
          <div class="gray">Total Stake:</div>
          <div class="fs30 mt-10">{{totalStake}}<span class="fs15">&nbsp;TOMO</span></div>
          <div v-if="totalStake > stake">
            <div class="gray">Remaning Stake:</div>
            <div class="fs30 mt-10">{{stake}}<span class="fs15">&nbsp;TOMO</span></div>
            <div class="remaining-stake">(remaning stake is less than total stake because the host is losing)</div>
          </div>
        </div>
        <div v-else>You will receive revenue every day and can withdraw anytime you want. (Min stake is {{minAmount}} TOMO)</div>
        <div class="input mt50">
          <label>Enter Amount:</label>
          <input v-model="amount" type="number" @change="changeAmount"/>
        </div>
        <button class="btn primary mt10" @click="joinStakePool">JOIN</button>
      </div>
      <div v-else>
        <span :style="{color: !isError ? 'green' : 'red'}">{{msg}}</span>
      </div>
    </div>
  </div>
</template>

<script>
import QRCode from '@xkeshi/vue-qrcode';
import _store from '../../store';
import Contract from '../../contracts';
import utils from '../../utils';

export default {
  components: {
    QRCode
  },
  data() {
    return {
      store: _store,
      amount: 500,
      minAmount: 500,
      stake: 0,
      totalStake: 0,
      isInPool: false,
      msg: '',
      isError: false,
    }
  },
  created() {
    this.getMin();
    Contract.get.stake(this.store.address)
    .then(stake => {
      this.isInPool = stake.isInPool;
      this.stake = utils.toTOMO(stake.amount);
      this.totalStake = utils.toTOMO(stake.totalStake);
    });
  },
  methods: {
    async getMin() {
      this.minAmount = await Contract.get.getMinAmountForJoin(this.store.address);
      this.amount = this.amount >= this.minAmount ? this.amount : this.minAmount;
    },
    changeAmount() {
      this.amount = this.amount >= this.minAmount ? this.amount : this.minAmount;
    },
    async joinStakePool() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        this.minAmount = await Contract.get.getMinAmountForJoin(this.store.address);
        if (this.amount < this.minAmount) {
          this.amount = this.minAmount;
          return;
        }
        var hash = await Contract.joinPool(this.amount);
        this.isSubmitting = false;
        this.msg = 'Your transaction is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = 'Join pool successfully';
        this.store.updateBalance();
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot join pool. Please try again.';
        this.isError = true;
      }
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
  color: red;
  font-family: sans-serif;
  font-size: 12px !important;
  margin-top: -10px;
}
</style>

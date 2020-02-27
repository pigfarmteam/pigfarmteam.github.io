<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container" style="margin-top: 100px;">
      <button class="modal-close-btn" @click="() => store.isShowWithdrawModal = false" />
      <div class="modal-title">
        Withdraw from stake
      </div>
      <div v-if="msg">
        <span :style="{color: !isError ? 'green' : 'red'}">{{msg}}</span>
      </div>
      <div v-else-if="!isLoading">
        <div class="gray">Your stake:</div>
        <div class="fs30 mt-15">{{stake}}<span class="fs15">&nbsp;TOMO</span></div>
        <div v-if="isInPool" class="gray">Revenue:</div>
        <div v-if="isInPool" class="fs40 mt-15 green">{{revenue}}<span class="fs25">&nbsp;TOMO</span></div>
        <div v-if="isRequestQuitPool" style="color: orange; margin-top: 10px">
          We will calculate pool and distribute profit or loss, therefroce you may receive more/less than total amount you are seeing.
          <button class="btn mt10 primary" @click="quitPool">Agree and Quit pool</button>
        </div>
        <div v-else-if="isInPool">
          <button class="btn primary mt10" @click="withdraw">Withdraw Your Revenue</button>
          <button class="btn mt10 secondary" @click="requestQuitPool">Quit Pool</button>
        </div>
        <div v-else>
          <button class="btn mt10 primary" @click="quitPool">Withdraw Your Stake</button>
        </div>
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
      isLoading: true,
      store: _store,
      amount: 1,
      stake: 0,
      isInPool: false,
      revenue: 0,
      msg: '',
      isError: false,
      isRequestQuitPool: false
    }
  },
  async created() {
    Contract.get.stake(this.store.address)
    .then(stake => {
      this.stake = utils.toTOMO(stake.amount);
      this.revenue = utils.toTOMO(stake.profit);
      this.isInPool = stake.isInPool;
      this.isLoading = false;
    });
  },
  methods: {
    updateCurrentBlock(lastBlock) {
      this.currentBlock = parseInt(lastBlock.number);
    },
    requestQuitPool() {
      this.isRequestQuitPool = true;
    },
    async withdraw() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        var hash = await Contract.withdrawProfit();
        this.isSubmitting = false;
        this.msg = 'Your transaction is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = 'Withdraw successfully';
        this.store.updateBalance();
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot withdraw. Please try again.';
        this.isError = true;
      }
    },
    async quitPool() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        var hash = await Contract.quitPool();
        this.isSubmitting = false;
        this.msg = 'Your request is in processing';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Withdrawn TOMO to your balance`;
        this.store.updateBalance();
      }
      catch(ex) {
        this.isSubmitting = true;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot quit qool. Please try again.';
        this.isError = true;
      }
    }
  }
}
</script>

<style scoped>
.withdraw-qr {
  width: 130px;
  height: 130px;
  margin: auto;
}

.withdraw-qr canvas {
    height: 130px;
    width: 130px;
}

.withdraw-qr-description {
  font-family: monospace;
  line-height: 1;
  margin-top: 10px;
  font-size: 15px;
  color: gray;
  text-align: center;
}
</style>

<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container" style="margin-top: 100px;">
      <button class="modal-close-btn" @click="() => store.isShowDonateForPrizePoolModal = false" />
      <div class="modal-title">
        Donate For Leader Board Prize
      </div>
      <div v-if="!msg">
        <div>We appreciate your contribution. Your help will make our game become great. Thank you!</div>
        <div class="input mt50">
          <label>Enter Amount:</label>
          <input v-model="amount" type="number"/>
        </div>
        <button class="btn primary mt10" @click="donate">DONATE</button>
      </div>
      <div v-else>
        <span :style="{color: !isError ? 'green' : 'red'}">{{msg}}</span>
        <button v-if="isError" class="btn primary mt10" @click="tryAgain">Try Again</button>
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
      amount: 1,
      msg: '',
      isError: false
    }
  },
  methods: {
    tryAgain() {
      this.msg = "";
      this.isError = false;
    },
    async donate() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.amount > 500) {
          this.msg = `We appreciate your contribution, however ${this.amount} TOMO is a big amount. Please try with maximum is 500 TOMO`;
          this.isError = true;
          return;
        }
        var hash = await Contract.prizeForLeaderBoard(this.amount);
        this.isSubmitting = false;
        this.msg = 'Your transaction is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `${this.amount} TOMO was contributed to the prize. Thank you!`;
        this.store.updateBalance();
        this.store.currentPrize = await Contract.get.totalPrize();
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot donate. Please try again.';
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

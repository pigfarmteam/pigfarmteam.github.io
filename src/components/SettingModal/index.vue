<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container" style="margin-top: 100px; max-height: 400px; overflow: auto;">
      <button class="modal-close-btn" @click="() => store.isShowSettingModal = false" />
      <div class="modal-title">
        Setting
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Withdraw:</label>
          <input style="width: 55%" v-model="withdrawAmount" type="number" placeholder="Amount"/>
          <input style="width: 55%" v-model="withdrawAdd" placeholder="Receive address"/>
          <button style="width: 30%" class="btn secondary" @click="withdraw">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Payout Level:</label>
          <input style="width: 55%" v-model="payout" type="number" placeholder="10 - 1000"/>
          <button style="width: 30%" class="btn secondary" @click="setPayout">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Revenue:</label>
          <input style="width: 55%" v-model="revenue" type="number" placeholder="1 - 15"/>
          <button style="width: 30%" class="btn secondary" @click="setRevenue">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Referral:</label>
          <input style="width: 55%" v-model="referral" type="number" placeholder="500 - 1000"/>
          <button style="width: 30%" class="btn secondary" @click="setReferral">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>LeaderBoard:</label>
          <input style="width: 55%" v-model="leaderBoard" type="number" placeholder="500 - 1000"/>
          <button style="width: 30%" class="btn secondary" @click="setPrizeForLeaderBoard">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Min Bet:</label>
          <input style="width: 55%" v-model="minBet" placeholder="0.1 - 10"/>
          <button style="width: 30%" class="btn secondary" @click="setMinBet">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Add Croupier:</label>
          <input style="width: 55%" v-model="croupier" placeholder="address"/>
          <button style="width: 30%" class="btn secondary" @click="addCroupier">Submit</button>
        </div>
      </div>
      <div v-if="!msg">
        <div class="input mt30">
          <label>Remove Croupier:</label>
          <input style="width: 55%" v-model="croupier" placeholder="address"/>
          <button style="width: 30%" class="btn secondary" @click="removeCroupier">Submit</button>
        </div>
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
      payout: '',
      msg: '',
      withdrawAmount: '',
      withdrawAdd: _store.address,
      revenue: '',
      referral: '',
      leaderBoard: '',
      minBet: '',
      croupier: '',
      isError: false
    }
  },
  async created() {
    this.payout = await Contract.get.getPrizePerBetLevel();
  },
  methods: {
    tryAgain() {
      this.msg = "";
      this.isError = false;
    },
    async setPayout() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.payout < 10 || this.payout > 1000) {
          this.msg = `Value from 10 to 1000`;
          this.isError = true;
          return;
        }
        var hash = await Contract.setPrizeLevel(this.payout);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async setRevenue() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.revenue < 1 || this.revenue > 15) {
          this.msg = `Value from 1 to 15`;
          this.isError = true;
          return;
        }
        var hash = await Contract.setRevenueForOperator(this.revenue);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async setReferral() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.referral < 500 || this.referral > 1000) {
          this.msg = `Value from 500 to 1000`;
          this.isError = true;
          return;
        }
        var hash = await Contract.setRefferalReward(this.referral);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async setPrizeForLeaderBoard() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.leaderBoard < 500 || this.leaderBoard > 1000) {
          this.msg = `Value from 500 to 1000`;
          this.isError = true;
          return;
        }
        var hash = await Contract.setPrizeForLeaderBoard(this.leaderBoard);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async setMinBet() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.minBet < 0.1 || this.minBet > 10) {
          this.msg = `Value from 0.1 to 10`;
          this.isError = true;
          return;
        }
        var hash = await Contract.setMinBet(this.minBet);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async addCroupier() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.croupier < 1 || this.croupier > 15) {
          this.msg = `Value from 1 to 15`;
          this.isError = true;
          return;
        }
        var hash = await Contract.addCroupier(this.croupier);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async removeCroupier() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        if (this.croupier < 1 || this.croupier > 15) {
          this.msg = `Value from 1 to 15`;
          this.isError = true;
          return;
        }
        var hash = await Contract.removeCroupier(this.croupier);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },
    async withdraw() {
      if (this.isSubmitting) return;
      this.isSubmitting = true;
      try {
        var hash = await Contract.operatorWithdraw(this.withdrawAdd, this.withdrawAmount);
        this.isSubmitting = false;
        this.msg = 'Your setting is in processing.';
        var tx = await Contract.get.checkTx(hash);
        this.msg = `Done`;
      }
      catch(ex) {
        this.isSubmitting = false;
        if (ex.toString().toLowerCase().indexOf('user denied transaction signature') >= 0) {
          return;
        }
        console.error(ex);
        this.msg = 'Error, Cannot setup. Please try again.';
        this.isError = true;
      }
    },

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

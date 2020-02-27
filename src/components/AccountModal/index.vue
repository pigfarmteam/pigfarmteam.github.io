<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container text-center">
      <button class="modal-close-btn" @click="() => store.isShowAccountModal = false" />
      <div class="modal-title">
        Your Account
      </div>
      <div style="margin-bottom: 10px;">
        <Address :address="store.address" />
      </div>
      <button class="btn primary" @click="stakePool">
        {{stake == -1 ? '...' :
          stake == 0 ? 'JOIN STAKE POOL' : 'MANAGE YOUR STAKE'}}
      </button>
      <button v-if="account.connectStatus != 'tomowallet'" class="btn secondary mt10" @click="logout">LOGOUT</button>
    </div>
  </div>
</template>

<script>
import _store from '../../store';
import Contract from '../../contracts';
import Address from './Address';

export default {
  components: {
    Address
  },
  data() {
    return {
      store: _store,
      account: Contract.accountInfo(),
      stake: -1,
      requestQuitPool: false
    }
  },
  created() {
    Contract.get.stake(this.store.address)
    .then(stake => {
      this.stake = stake.amount
      this.requestQuitPool = parseInt(stake.quitAtBlock) > 0;
    });
  },
  methods: {
    logout() {
      sessionStorage.clear();
      Contract.logout();
      this.store.isShowAccountModal = false;
      this.store.address = '';
      this.store.isAutoRoll = false;
      this.store.isRolling = false;
    },
    stakePool() {
      if (this.stake == -1) return;

      this.store.isShowAccountModal = false;
      if (this.stake > 0) {
        if (this.requestQuitPool) {
          this.store.isShowWithdrawModal = true;
        }
        else {
          this.store.isShowManageStakeModal = true;
        }
      }
      else {
        this.store.isShowJoinStakePoolModal = true;
      }
    }
  }
}
</script>


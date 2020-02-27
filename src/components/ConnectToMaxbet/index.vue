<template>
  <div style="padding: 20px;">
    <div>
      <button v-if="!isLoging" class="btn warning" @click="login">
        Connect to Play and Stake
        <br/>with Maxbet. It's free!
      </button>
      <button v-else class="btn warning">
        Connecting...
      </button>
    </div>
  </div>
</template>

<script>
import _store from '../../store';
import Contract from '../../contracts';
import web3 from 'web3';

export default {
  data() {
    return {
      isLoging: false,
    }
  },
  methods: {
    async login() {
      try {
        if (this.isLoging) return;
        this.isLoging = true;
        var ref = localStorage.referralAddress || location.search || '';
        ref = ref.replace('?', '');
        if (!web3.utils.isAddress(ref)) {
          ref = window.MaxBetSetting.defaultReferralAddress;
        }
        var hash = await Contract.loginToSmartContract(ref);
        await Contract.get.checkTx(hash);
        _store.isLogon = true;
        this.isLoging = false;
      }
      catch (ex) {
        _store.isLogon = false;
        this.isLoging = false;
        var errMsg = ex.toString().toLowerCase();
        if (errMsg.indexOf('user denied transaction signature') >= 0 || errMsg.indexOf('cancelled') >= 0) {
          return;
        }
        window.handleError(ex);
      }
    }
  }
}
</script>
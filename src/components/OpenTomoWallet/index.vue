<template>
  <div v-if="show" class="open-tomowallet animated slideInUp" style="cursor: pointer;" @click="open">
    Play on TomoWallet
  </div>
</template>

<script>
import _store from '../../store';
import web3 from 'web3';

export default {
  data() {
    return {
      store: _store
    }
  },
  computed: {
    show() {
      return !this.store.address// && (!window.web3 || !window.web3.currentProvider)
    }
  },
  methods: {
    open() {
      var ref = localStorage.referralAddress || location.search || '';
      ref = ref.replace('?', '');
      if (web3.utils.isAddress(ref)) {
        window.location = `tomochain://dapp?url=https://maxbet.pigfarm.io?${ref}`
      }
      else {
        window.location = `tomochain://dapp?url=https://maxbet.pigfarm.io`
      }
    }
  }
}
</script>

<style>
.open-tomowallet {
  position: fixed;
  bottom: 14px;
  background: linear-gradient(90deg, rgba(255,126,0,1) 0%, rgba(255,194,0,1) 100%);
  padding: 10px 20px;
  border-radius: 30px;
  box-shadow: 2px 5px 20px #3a3a3a;
  color: #ffffff;
  left: calc(50% - 105px);
  text-align: center;
  width: 170px;
}
</style>
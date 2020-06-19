<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container">
      <button class="modal-close-btn" @click="() => store.isShowLoginModal = false" />
      <div class="modal-title">
        Connect Your Wallet
      </div>
      <div v-if="status === 'select'">
        <button class="login-item" @click="connectMetamask">
          <img src="./pantograph.png" height="50px" />
          <div>Pantograph</div>
        </button>
        <button class="login-item" @click="connectMetamask">
          <img src="./metamask.png" height="50px" />
          <div>Metamask</div>
        </button>
        <button class="login-item" @click="() => status = 'privatekey'">
          <img src="./privatekey.png" height="50px" />
          <div>Private Key</div>
        </button>
        <button class="login-item" @click="() => status = 'recoverypharse'">
          <img src="./words.png" height="50px" />
          <div>12 words</div>
        </button>
        <!-- <button class="login-item">
          <img src="./newwallet.svg" height="50px" />
          <div>+ New Wallet</div>
        </button> -->
      </div>
      <div v-if="status === 'privatekey'">
        <div class="input">
          <label>Enter your Private Key:</label>
          <textarea v-model="privateKey" rows="3" type="text" />
        </div>
        <button class="btn primary" @click="connectPrivateKey">CONNECT</button>
      </div>
      <div v-if="status === 'recoverypharse'">
        <div class="input">
          <label>Enter your 12 words:</label>
          <textarea v-model="recoveryPhrase" rows="3"/>
        </div>
        <div class="input">
          <label>Enter HD path:</label>
          <input v-model="hdpath" />
        </div>
        <button class="btn primary mt10" @click="connectRecoveryPhrase">CONNECT</button>
      </div>
    </div>
  </div>
</template>

<script>
import _store from '../../store';
import Contract from '../../contracts';

export default {
  data() {
    return {
      store: _store,
      status: 'select',
      privateKey: '',
      recoveryPhrase: '',
      hdpath: "m/44'/889'/0'/0"
    }
  },
  methods: {
    connectTomoWallet() {
      if (confirm('Download TomoWallet to play in app')) {
        window.open('http://l.ead.me/bb0oA6');
      }
    },
    connectPrivateKey() {
      Contract.login({
        privateKey: this.privateKey
      }, (err, address) => {
        if (err) return alert(err);
        this.store.address = address;
        this.store.isShowLoginModal = false;
        sessionStorage.privateKey = this.privateKey;
      });
    },
    connectRecoveryPhrase() {
      Contract.login({
        privateKey: this.recoveryPhrase,
        hdpath: this.hdpath
      }, (err, address) => {
        if (err) return alert(err);
        this.store.address = address;
        this.store.isShowLoginModal = false;
        sessionStorage.privateKey = this.privateKey;
        sessionStorage.hdpath = this.hdpath;
      });
    },
    connectMetamask() {
      Contract.login({ metamask: true }, (err, address) => {
        if (err) return alert(err);
        this.store.address = address;
        this.store.isShowLoginModal = false;
      })
    }
  }
}
</script>


<style scoped>

.login-item {
  font-family: 'Baloo', serif;
  font-size: 17px;
  border: none;
  background: #ffffff;
  width: calc(50% - 12px);
  height: 115px;
  padding: 10px;
  border-radius: 10px;
  margin: 5px;
  margin-bottom: 10px;
  box-shadow: 2px 2px 10px #d6d6d6;
  outline: none;
  cursor: pointer;
  transition: 0.3s all;
}

.login-item:hover {
  background: #e6e6e6;
}
</style>



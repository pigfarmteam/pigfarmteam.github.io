<template>
  <div class="navbar-bound">
    <div id="navbar" class="navbar">
      <a class="leader-btn" @click="showHelp">
        <img width="21px" height="21px" src="./help.svg" />
      </a>
      <a v-if="isTomoWallet" class="chat-btn" :href="setting.telegram">
        <img width="21px" height="21px" src="./chat.svg" />
      </a>
      <a v-else class="chat-btn" target="__blank" :href="setting.telegram">
        <img width="21px" height="21px" src="./chat.svg" />
      </a>
      <div v-if="address" class="avatar" @click="showAccount">
        <img src='./avatar.svg'/>
      </div>
      <div v-if="address" class="account">
        <div class="fs15 op7">Your balance</div>
        <div class="fs25">
          <animated-number :value="store.balance" :formatValue="formatBalance" :duration="500"/><span class="fs15">&nbsp;TOMO</span>
        </div>
        <div v-if="addBalanceValue > 0" class="navbar-addbalance animated slideInUp" style="color: #00d208; right: 80px;">+{{addBalanceValue}}</div>
        <div v-if="subBalanceValue < 0" class="navbar-addbalance animated slideOutUp" style="color: #f44336">{{subBalanceValue}}</div>
      </div>
      <div v-if="!address" class="account">
        <button class="account-login" @click="login">Login</button>
      </div>
    </div>
  </div>
</template>

<script>
import Contract from '../../contracts';
import AnimatedNumber from "animated-number-vue";
import _store from '../../store';
import utils from '../../utils';

export default {
  components: {
    AnimatedNumber
  },
  data() {
    return {
      store: _store,
      isTomoWallet: Contract.accountInfo().connectStatus == 'tomowallet',
      addBalanceValue: 0,
      subBalanceValue: 0,
      setting: window.MaxBetSetting
    }
  },
  created() {
    this.store.updateBalance();
  },
  mounted() {
    // this.$refs.audio.volume = 0.2;
  },
  watch: {
    'store.address': {
      handler() {
        this.store.updateBalance();
      }
    }
  },
  computed: {
    address() {
      return this.store.address;
    }
  },
  methods: {
    showHelp() {
      this.store.isShowHelpModal = true;
    },
    login() {
      this.store.isShowLoginModal = true;
    },
    showAccount() {
      this.store.isShowAccountModal = true;
    },
    currentBalance() {
      return this.store.balance;
    },
    refreshBalance(animation) {
      if (animation) {
        clearTimeout(this.animationRefesh);
        this.animationRefesh = setTimeout(() => {
          Contract.get.balance(this.store.address).then(v => {
            var newBalance = utils.toTOMO(v);
            var d = newBalance - this.store.balance;
            d = parseFloat(d.toFixed(2));
            if (Math.abs(d) >= 1) {
              this.addBalance(d, false, true);
            }
          });
        }, 500);
      }
      else {
        this.store.updateBalance();
      }
    },
    addBalance(v, tryRefreshBalance, changeToBalance) {
      if (v < 0) {
        this.subBalanceValue = v;
        this.store.balance += changeToBalance ? v : 0;
        setTimeout(() => {
          this.subBalanceValue = 0;
          if (tryRefreshBalance) {
            this.store.updateBalance();
          }
        }, 1000);
      }
      else {
        // try {
        //   v > 0 && this.$refs.audio.play();
        // }
        // catch (ex) {}
        this.addBalanceValue = v;
        this.store.balance += changeToBalance ? v : 0;
        setTimeout(() => {
          this.addBalanceValue = 0;
          if (tryRefreshBalance) {
            this.store.updateBalance();
          }
        }, 1000);
      }
    },
    formatBalance(value) {
      if(this.store.balance === 0) {
        return '0';
      }
      if (this.store.balance < 0.01) {
        value = Math.floor(value * 10000) / 10000
        return value.toFixed(4);
      }
      value = Math.floor(value * 100) / 100
      return value.toFixed(2);
    }
  }
}
</script>

<style scoped>

.navbar-bound {
  height: 80px;
}

.navbar {
  padding: 15px 15px 5px 15px;
  color: #ffffff;
  overflow: hidden;
}

.navbar-addbalance {
  font-size: 30px;
  font-size: 30px;
  position: absolute;
  top: 8px;
  right: 51px;
}

@media (max-width: 767px) {
  .navbar-bound {
    height: 70px;
  }
  .navbar {
    background: #05042c;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 99;
  }
}

.account {
  text-align: right;
  float: right;
  line-height: 1.2;
  margin: 0 10px;
  position: relative;
}

.account-login {
  border-radius: 20px;
  background: #3498db;
  border: none;
  color: #ffffff;
  font-size: 17px;
  font-family: 'Baloo', serif;
  padding: 5px 10px;
  width: 90px;
  outline: none;
  transition: 0.3s all;
  cursor: pointer;
}

.account-login:hover {
  background: #076fb5;
}

.avatar {
  width: 40px;
  height: 40px;
  background: #FFC107;
  border-radius: 50px;
  border: 1px solid #ffffff;
  float: right;
  overflow: hidden;
  cursor: pointer;
}

.avatar img {
  width: 100%;
  height: 100%;
}

.leader-btn {
  outline: none;
  cursor: pointer;
  margin-top: 5px;
  float: left;
  padding: 7px;
  border-radius: 7px;
  background-image: linear-gradient( 0deg, rgb(165,0,79) 0%, rgb(168,0,115) 100%);
  box-shadow: 0px 5px 10px 0px rgba(0, 0, 0, 0.35);
  border: none;
  line-height: 0;
}

.chat-btn {
  outline: none;
  cursor: pointer;
  margin-top: 5px;
  float: left;
  padding: 7px;
  border-radius: 7px;
  border: none;
  margin-left: 12px;
  background: rgba(0, 150, 136, 0.7);
  line-height: 0;
}
</style>

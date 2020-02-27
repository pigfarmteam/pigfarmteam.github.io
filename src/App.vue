<template>
  <div id="app">
    <LoginModal v-if="store.isShowLoginModal" />
    <AccountModal v-if="store.isShowAccountModal" />
    <JoinStakePoolModal v-if="store.isShowJoinStakePoolModal" />
    <ManageStakeModal v-if="store.isShowManageStakeModal" />
    <WithdrawStakePoolModal v-if="store.isShowWithdrawModal" />
    <DonateForPrizePoolModal v-if="store.isShowDonateForPrizePoolModal" />
    <HelpModal v-if="store.isShowHelpModal" />
    <ErrorModal v-if="store.isShowErrorModal" />
    <SettingModal v-if="store.isShowSettingModal" />
    <Home />
    <ChatBox/>
    <OpenTomoWallet />
  </div>
</template>

<script>
import Home from './components/Home';
import LoginModal from './components/LoginModal';
import AccountModal from './components/AccountModal';
import JoinStakePoolModal from './components/JoinStakePoolModal';
import ManageStakeModal from './components/ManageStakeModal';
import DonateForPrizePoolModal from './components/DonateForPrizePoolModal';
import WithdrawStakePoolModal from './components/WithdrawStakePoolModal';
import HelpModal from './components/HelpModal';
import ErrorModal from './components/ErrorModal';
import SettingModal from './components/SettingModal';
import ChatBox from './components/ChatBox';
import OpenTomoWallet from './components/OpenTomoWallet';
import store from './store';
import Contract from './contracts';

export default {
  name: 'app',
  components: {
    Home,
    LoginModal,
    AccountModal,
    JoinStakePoolModal,
    ManageStakeModal,
    WithdrawStakePoolModal,
    HelpModal,
    ErrorModal,
    ChatBox,
    DonateForPrizePoolModal,
    SettingModal,
    OpenTomoWallet
  },
  data() {
    return {
      store: store
    }
  },
  created() {
    if (process.NODE_ENV != 'production' && location.hash) {
      var privateKeys = [
        'd83a227fdf69c7e86fce8800af37c21e2fec7ddd8127a3fb519a34c02078d282',
        'e53a67bc94db688bff894db74b57127f3d8b34fbea89989ee50559e59700e754',
        '9453e84ca1924933762bf0e33805f7d08ad58048050c20817bb8a712bea1c616',
        'a62d9853cea4ef63c3122c911e31b193c453572fae10f9552bd5465c399fae71',
        '08a189baa38df079dde16f4588f707f11304be07daf397c43a17e4188b9bc0a1',
        '7d6f5967ce120c9f26c3c8e09636e88e37d6751f9934c5f6e69d4f8415f92100',
        'd5dc2bb772e9f80f54d85410322d2bb036086fa753a03456f88b5e21b55c4008',
        '989a515d5cc4c3c57300e84133e00eb4647b9e6d26c4d28a93f73d6487a83f85',
        '0c4b76642172e03adb074aa535671fefdae895f3b90eb15391e5ad3bc4fdae73',
        '77cde77d3498463f59a40f8bad742b84f1e4e7e557b157b1082a55bfcf868a04',
        'fe4e5952126068f9d99535442c69fd4c99137046090ec0efc22263f2fa92a48d',
        '6d461b530662b3164fa63d9dadb9ca9ed4cf594016f99e91a4731a44049ab5ee',
        '1871cf9b4dd19bd4fff7a3b2c580824d5ba532e8939c72dcd2306064a5a68baa',
        'e3fd27b0f4f43d4ca42f6eb46e3b2bba545aa304482175792a364303f9984e61',
        'e4a91bec6dc25f2630e888987cfd0a70fc8f02eaf210395ca8ee487ae58f5bf6'
      ]
      sessionStorage.privateKey = privateKeys[parseInt(location.hash.substring(1))];
    }
    if (sessionStorage.privateKey) {
      Contract.login({
        address: sessionStorage.address,
        privateKey: sessionStorage.privateKey,
        hdpath: sessionStorage.hdpath
      }, (err, address) => {
        console.log(address);
        store.address = address;
      });
    }
    else if (window.web3 && window.web3.currentProvider) {
      if (window.web3.currentProvider.isTomoWallet) {
        Contract.login({
          tomowallet: true
        }, (err, address) => {
          console.log(address);
          store.address = address;
        });
      }
      else if (!window.web3.currentProvider.isMetaMask) {
        Contract.login({
          metamask: true
        }, (err, address) => {
          console.log(address);
          store.address = address;
        });
      }
    }
  }
}
</script>
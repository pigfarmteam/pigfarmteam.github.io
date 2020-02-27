import Vue from 'vue'
import App from './App.vue'
import './styles/style.css'
import './styles/aminated.css'
import './styles/modal.css'
import './styles/button.css'
import './styles/input.css'
import store from './store'
import web3 from 'web3';

Vue.config.productionTip = false
window.handleError = (ex) => {
  console.error(ex);
  store.showError(ex && ex.toString() || 'Have an error, refresh and try again please!');
}

if (location.search) {
  var ref = (location.search || '').replace('?', '');
  if (web3.utils.isAddress(ref)) {
    localStorage.referralAddress = ref;
    // location.search = '';
  }
}

new Vue({
  render: h => h(App),
}).$mount('#app')

<template>
  <div style="">
    <div class="roll-auto">
      <label class="switch">
        <input v-model="store.isAutoRoll" type="checkbox" @change="v => autoRoll(v)">
        <span class="slider round"></span>
      </label>
      <div>
        <span>Auto Roll</span>
      </div>
    </div>
    <div class="rol-button">
      <button v-if="isRolling" @click="$emit('click')">
        ROLLING<span>.</span><span>.</span><span>.</span>
      </button>
      <button v-else @click="$emit('click')">
        ROLL
      </button>
    </div>
  </div>
</template>

<script>
import Contract from '../../contracts';
import _store from '../../store';

export default {
  props: ['isRolling'],
  data() {
    return {
      store: _store
    }
  },
  methods: {
    autoRoll(v) {
      if (Contract.accountInfo().connectStatus === 'metamask') {
        this.store.isAutoRoll = false;
        alert('Auto roll only available for login with private key or TomoWallet');
      }
    }
  }
}
</script>


<style scoped>
.roll-auto {
  color: white;
  width: 100px;
  float: left;
  /* display: inline-block; */
}

.rol-button {
  width: calc(100% - 100px);
  float: right;
}

button {
  cursor: pointer;
  border: none;
  outline: none;
  background: url(./bg.png);
  background-size: 100% 100%;
  height: 50px;
  width: 100%;
  font-family: 'Baloo', serif;
  font-size: 30px;
  color: white;
  text-shadow: -2px 2px #9b4b00;
}

button span {
  animation-name: blink;
  animation-duration: 1s;
  animation-iteration-count: infinite;
  animation-fill-mode: both;
}
button span:nth-child(2) {
  animation-delay: .2s;
}
button span:nth-child(3) {
  animation-delay: .4s;
}

@keyframes blink {
  0% {
    opacity: .2;
  }
  20% {
    opacity: 1;
  }
  100% {
    opacity: .2;
  }
}


.switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 29px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
  outline: none;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  -webkit-transition: .4s;
  transition: .4s;
}

.slider:before {
  position: absolute;
  content: "";
  height: 23px;
  width: 23px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  -webkit-transition: .4s;
  transition: .4s;
}

input:checked + .slider {
  background-color: #2196F3;
}

input:checked + .slider:before {
  transform: translateX(21px);
}

/* Rounded sliders */
.slider.round {
  border-radius: 34px;
}

.slider.round:before {
  border-radius: 50%;
}


</style>


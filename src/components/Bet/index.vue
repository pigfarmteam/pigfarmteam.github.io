<template>
  <div class="bet">
    <div class="fs20 text-center">Your prediction</div>
    <div class="bet-slider">
      <Slider ref="slider" :value="value" v-bind="options"
        @callback="v => changeNumber(v, true)"
        @drag-start="() => options.tooltip = isTouchScreen ? 'always' : 'hover'"
        @drag-end="() => options.tooltip = isTouchScreen ? false : 'hover'"/>
    </div>
    <div class="text-center">
      <button class="bet-btn" :class="!isOver && 'bet-btn-under-active'" style="transform: translateX(3px);" @click="() => changeOver(false)">
        Under
      </button>
      <button class="bet-btn" :class="isOver && 'bet-btn-over-active'" @click="() => changeOver(true)">
        Over
      </button>
    </div>
    <div class="bet-chance">
      <div style="width: calc(55%)"><span class="op5">Win Chance:</span>&nbsp;&nbsp;<span class="fs20">{{winChance}}%</span></div>
      <div style="width: calc(45% - 4px)"><span class="op5">Multiplier:</span>&nbsp;&nbsp;x<span class="fs20">{{multiplier}}</span></div>
    </div>
    <div class="bet-amount">
      <label>Bet Amount</label>
      <button class="min-btn" @click="betMin">min</button>
      <input v-model="amount" type="number" @blur="scrollTop" @keypress="keyPress" @change="changeAmount">
      <button class="max-btn" @click="betMax">max</button>
    </div>
    <div class="bet-payout">
      <label>Payout on WIN</label>
      <div>{{Math.floor(amount * multiplier * 1000) / 1000}}</div>
    </div>
  </div>
</template>

<script>
import Slider from './Slider';
import Contract from '../../contracts';
import _store from '../../store';
import utils from '../../utils';

export default {
  components: {
    Slider
  },
  data() {
    var isTouchScreen = ('ontouchstart' in window || navigator.maxTouchPoints);
    return {
      store: _store,
      value: 50,
      amount: 1,
      isOver: false,
      isTouchScreen: isTouchScreen,
      maxBet: 100,
      minBet: 0.5,
      houseEdge: 1,
      options: {
        width: 'auto',
        height: 10,
        min: 0,
        max: 99,
        clickable: false,
        bgStyle: {
          background: '#A5004F'
        },
        tooltipStyle: {
          backgroundColor: "#3498db",
          borderColor: "#3498db",
        },
        tooltip: isTouchScreen ? false : 'hover',
        'dot-width': 30,
        'dot-height': 30
      }
    }
  },
  async created() {
    this.refershAmount();
    this.houseEdge = await Contract.get.houseEdge();
  },
  computed: {
    winChance() {
      if(this.isOver) {
        return 99 - this.value;
      }
      else {
        return this.value;
      }
    },
    multiplier() {
      return Math.floor((100000 - this.houseEdge * 1000) / this.winChance) / 1000;
    }
  },
  watch: {
    'amount': {
      handler(val) {
        this.store.isAutoRoll = false;
      }
    }
  },
  methods: {
    scrollTop() {
      window.scrollTo(0, 0);
    },
    getRange(cb) {
      Contract.get.betRange(this.value, this.isOver)
      .then(v => {
        this.maxBet = v.max;
        this.minBet = v.min;
        cb && cb();
      })
      .catch(ex => {
        window.handleError(ex);
      })
    },
    set(number, isOver, amount) {
      this.isOver = isOver;
      this.number = number;
      this.amount = amount;
    },
    get() {
      return {
        isOver: this.isOver,
        amount: this.amount >= this.minBet ?
          (this.amount < this.maxBet ? this.amount : this.maxBet) : this.minBet,
        number: this.value
      }
    },
    changeOver(isOver) {
      this.store.isAutoRoll = false;
      this.options.tooltipStyle.backgroundColor = isOver ? '#A5004F' : '#3498db';
      this.options.tooltipStyle.borderColor = isOver ? '#A5004F' : '#3498db';
      this.isOver = isOver;
      this.changeNumber(this.value, false);
    },
    fixValue(v) {
      if (this.isOver) {
        v = v >= 4 ? v : 4;
        v = v <= 98 ? v : 98;
      }
      else {
        v = v >= 1 ? v : 1;
        v = v <= 95 ? v : 95;
      }

      return v;
    },
    betMax() {
      clearTimeout(this.timeoutGetRange);
      this.getRange(async () => {
        var v = this.store.balance;
        this.amount = this.maxBet > v ? v : this.maxBet;
      });
    },
    betMin() {
      clearTimeout(this.timeoutGetRange);
      this.getRange(async () => {
        this.amount = this.minBet;
      });
    },
    refershAmount() {
      clearTimeout(this.timeoutGetRange);
      this.getRange(async () => {
        this.amount = this.amount < this.minBet ? this.minBet : this.amount;
        this.amount = this.amount > this.maxBet ? this.maxBet : this.amount;
      });
    },
    async changeAmount(e) {
      this.store.isAutoRoll = false;
      if (e.currentTarget.value) {
        var value = parseFloat(e.currentTarget.value);

        this.amount = value >= this.minBet ?
          (value < this.maxBet ? value : this.maxBet) : this.minBet;
      }
    },
    changeNumber(v, noCB) {
      this.store.isAutoRoll = false;
      this.value = this.fixValue(v);
      if (v != this.value) {
        this.$refs.slider.setValue(this.value, noCB);
      }
      clearTimeout(this.timeoutGetRange);
      this.timeoutGetRange = setTimeout(() => this.getRange(() => {
        this.amount = this.amount < this.minBet ? this.minBet : this.amount;
        this.amount = this.amount > this.maxBet ? this.maxBet : this.amount;
      }), 500);
    },
    keyPress(e) {
      if (e.charCode == 13 || e.keyCode == 13 || e.code == 'Enter') {
        e.currentTarget.blur();
      }
    }
  }
}
</script>


<style scoped>
.bet {
  color: #ffffff;
}

.bet-slider {
  padding: 0 30px;
}

.bet-btn {
  border: none;
  color: #ffffff;
  font-size: 17px;
  font-family: 'Baloo', serif;
  padding: 5px 10px;
  width: 120px;
  outline: none;
  background: #ffffff4d;
  transition: 0.3s all;
  opacity: 0.6;
  cursor: pointer;
}

.bet-btn-over-active {
  background: rgb(140,25,80);
  opacity: 1;
}

.bet-btn-under-active {
  background: #3498db;
  opacity: 1;
}

.bet-btn:first-child {
  border-radius: 20px 0 0 20px;
  border-right: none;
}

.bet-btn:last-child {
  border-radius: 0 20px 20px 0;
  border-left: none;
}

.bet-chance {
  padding: 15px;
  margin-bottom: 15px;
}

.bet-chance div {
  display: inline-block;
  width: calc(50% - 2px);
}

.bet-chance div:first-child {
  text-align: left;
}
.bet-chance div:last-child {
  text-align: left;
}

.bet-amount {
  width: calc(55% - 15px);
  padding-left: 15px;
  text-align: left;
  position: relative;
  margin-top: 15px;
  display: inline-block;
}

.bet-amount label {
  position: absolute;
  top: -25px;
  left: 15px;
}

.bet-amount input {
  outline: none;
  border: 2px solid #00a9e9;
  border-radius: 10px;
  font-size: 25px;
  font-family: 'Baloo', serif;
  background: transparent;
  color: #ffffff;
  text-align: left;
  width: calc(100% - 50px);
  background: rgba(255, 255, 255, 0.2);
  padding: 0px 15px;
  position: relative;
  text-align: center;
}

.bet-amount .max-btn {
  position: absolute;
  z-index: 4;
  background: #00a9e9;
  right: 16px;
  top: 1px;
  padding: 10px 7px;
  color: white;
  border: none;
  outline: none;
  font-size: 14px;
  font-family: 'Baloo', serif;
  border-radius: 0 10px 10px 0;
  cursor: pointer;
  min-width: 41px;
}
.bet-amount .min-btn {
  position: absolute;
  z-index: 4;
  background: #00a9e9;
  left: 14px;
  top: 1px;
  padding: 10px 7px;
  color: white;
  border: none;
  outline: none;
  font-size: 14px;
  font-family: 'Baloo', serif;
  border-radius: 10px 0 0 10px;
  cursor: pointer;
  min-width: 41px;
}

.bet-payout {
  width: calc(45% - 34px);
  padding-right: 15px;
  text-align: left;
  position: relative;
  margin-top: 15px;
  display: inline-block;
}

.bet-payout label {
  position: absolute;
  top: -25px;
  left: 0;
}

.bet-payout div {
  outline: none;
  border: 2px solid #f4de47;
  border-radius: 10px;
  font-size: 25px;
  font-family: 'Baloo', serif;
  background: transparent;
  color: #ffffff;
  text-align: left;
  width: calc(100% - 18px);
  background: rgba(255, 255, 255, 0.2);
  padding: 0px 15px;
  text-shadow: 0px 0px 10px #e28415;
}
</style>

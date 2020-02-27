<template>
  <div class="yourbet">
    <img class="yb-square" src="./pixel.png" />
    <div class="yb-container">
      <div class="yb-text">
        <img width="100%" src="./YourBet.png" />
      </div>
      <div class="yb-bet">
        <div class="yb-amount">{{amount}}&nbsp;<span class="yb-tomo">TOMO</span></div>
        <div class="yb-num">{{isOver ? 'Over' : 'Under'}}&nbsp;{{number > 9 ? number : `${number}`}}</div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: ['isOver', 'number', 'amount']
}
</script>


<style scoped>
.yourbet {
  width: calc(50% - 2px);
  display: inline-block;
  position: relative;
  line-height: 0;
}

.yb-container {
  background-image: linear-gradient( 180deg, rgb(140,25,80) 0%, rgb(54,1,54) 100%);
  border-radius: 20px;
  position: absolute;
  top: 5px;
  bottom: 5px;
  left: 5px;
  right: 5px;
}

.yb-square {
  width: 100%;
}

.yb-text {
  margin-top: 10px;
  margin-left: 5px;
  margin-right: 5px;
}

.yb-amount {
  font-size: 30px;
}

.yb-tomo {
  font-size: 17px;
}

.yb-num {
  font-size: 30px;
}

.yb-bet {
  text-shadow: 1px 1px 5px black;
  line-height: 1.5;
  text-align: center;
  color: #ffffff;
}

@media (max-width: 767px) {
  .yb-amount {
    font-size: 25px;
  }

  .yb-tomo {
    font-size: 15px;
  }
  .yb-num {
    font-size: 25px;
  }
}
</style>

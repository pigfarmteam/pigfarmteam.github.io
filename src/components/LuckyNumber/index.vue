<template>
  <div class="luckynumber">
    <img class="ln-square" src="./pixel.png" />
    <div class="ln-container">
      <div class="ln-text">
        <img width="100%" src="./LuckyNumber.png" />
      </div>
      <div class="ln-number">
        {{!isDrawing || isAutoRoll ? number : (tmpNum > 9 ? tmpNum : `0${tmpNum}`)}}
        <div v-if="isAutoRoll && isDrawing" class="ln-autoRoll">
          {{(tmpNum > 9 ? tmpNum : `0${tmpNum}`)}}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: ['number', 'isDrawing', 'isAutoRoll'],
  data() {
    return {
      tmpNum: 0
    }
  },
  created() {
    this.timer = setInterval(() => {
      this.tmpNum = Math.floor(Math.random() * 1000) % 100;
    }, 100);
  },
  destroyed() {
    clearInterval(this.timer);
  }
}
</script>


<style scoped>
.luckynumber {
  width: calc(50% - 2px);
  display: inline-block;
  position: relative;
  line-height: 0;
}

.ln-container {
  background-image: linear-gradient( 180deg, rgb(140,25,80) 0%, rgb(54,1,54) 100%);
  border-radius: 20px;
  position: absolute;
  top: 5px;
  bottom: 5px;
  left: 5px;
  right: 5px;
  overflow: hidden;
}

.ln-square {
  width: 100%;
}

.ln-text {
  margin-top: 10px;
  margin-left: 5px;
  margin-right: 5px;
}

.ln-number {
  font-size: 80px;
  text-shadow: 1px 1px 5px black;
  line-height: 1;
  text-align: center;
  color: #ffffff;
  position: relative;
}

.ln-autoRoll {
  text-align: center;
  color: rgba(255, 255, 255, 0.2);
  position: absolute;
  top: 0;
  font-size: 110px;
  left: 0;
  right: 0;
  bottom: 0;
  text-shadow: none;
  line-height: 0.8;
}

@media (min-width: 768px) {
  .ln-number {
    font-size: 120px;
  }
}
</style>

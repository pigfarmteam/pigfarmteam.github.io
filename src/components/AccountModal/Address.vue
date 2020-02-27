<template>
  <div>
    <div class="address-qr">
      <QRCode :value="address" :options="{ size: 150 }"></QRCode>
    </div>
    <div class="address-text">
      <div>
        {{address}}
        <button class="address-coppy-btn" :data-clipboard-text="address">
          <img src="./coppy.svg" width="15px" />{{isCopied ? '&nbsp;copied' : ''}}
        </button>
      </div>
    </div>
  </div>
</template>

<script>

import QRCode from '@xkeshi/vue-qrcode';
import ClipboardJS from 'clipboard';
export default {
  props: ['address'],
  components: {
    QRCode
  },
  data() {
    return {
      isCopied: false
    }
  },
  mounted() {
    var clipboard = new ClipboardJS('.address-coppy-btn');
    clipboard.on('success', (e) => {
      this.isCopied = true;
      setTimeout(() => {
        this.isCopied = false;
      }, 5000);
      e.clearSelection();
    });
  }
}
</script>

<style lang="css" scoped>
.address-qr {
  width: 130px;
  height: 130px;
  margin: auto;
}

.address-qr canvas {
    height: 130px;
    width: 130px;
}

.address-text {
  word-break: break-all;
  text-align: center;
  margin-top: 15px;
}

.address-coppy-btn {
  font-size: 15px;
  font-family: 'Baloo', serif;
  color: #268bd8;
  margin-left: 10px;
  display: inline-flex;
  align-items: center;
  border-radius: 5px;
  box-shadow: 0px 0px 2px rgba(0, 0, 0, 0.3);
  background: transparent;
  border: none;
  min-height: 22px;
  cursor: pointer;
  outline: none;
}
</style>

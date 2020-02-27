<template>
  <div class="modal animated fadeIn fast">
    <div class="modal-container">
      <button class="modal-close-btn" @click="() => store.isShowHelpModal = false" />
      <div class="modal-title">
        INTRODUCTION
      </div>
      <div style="height: 300px; overflow: auto;">
        <div class="text">
          MaxBet, the most sophisticated, fair, secure, unique economics incentive mechanism gamble<br/><br/>

          MaxBet aims to become a new standard dice game run on the scalable
          TomoChain blockchain with its innovative decentralized solutions
          for its underlying economics mechanism. Instead of having a single host,
          there can be multiple hosts, namely investors, staked into the gamble smart contract<br/><br/>

          <a href="/static/paper.pdf">Read our paper</a> for more details.

        </div>
        <div class="blue mt10">HOW TO PLAY?</div>
        <video controls width="100%" height="180px" poster="/static/poster.png">
          <source src="/static/howtoplay.mp4" type="video/mp4">
          Your browser does not support the video tag.
        </video>
        <div class="blue mt10">HOW TO BECOME A STAKER?</div>
        <div class="text">
          We design the most sophisticated and decentralized Dice gamble where there
          are not only one host, but many hosts that stake into a staking pool.
          There are two types of actors. Any TOMO holder can become an investor by
          making the deposit, which is technically done by sending a transaction
          with a minimum investment amount to the MaxBet smart contract. The current minimum
          investment amount is set at 1000 TOMO.<br/><br/>

          To become a staker, click on the avatar on your top right, then click on <b>Join stake pool</b> button.
          After that, you will be asked the amount of TOMO to stake to our Smart Contract. At least 1000 TOMO<b>(*)</b> should be staked to the Smart Contract.<br/>
          Once staked, you can withdraw your TOMO anytime you want, and the most important thing is <b>"No one is controlling your funds!"</b>.<br/>

          <b>(*)</b> In case there are already 15 stakers in the staking pool, you must stake more than one of the 15 stakers in the pool to become a staker and earn profits.
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _store from '../../store';

export default {
  data() {
    return {
      store: _store
    }
  }
}
</script>

<style scoped>
.text {
  font-family: serif;
}
</style>

<template>
  <div class="gameinfo">
    <div class="gameinfo-tab">
      <div class="gameinfo-tab-item" :class="status === 'players' && 'gameinfo-tab-item-active'" @click="status = 'players'">All Bets</div>
      <div class="gameinfo-tab-item" :class="status === 'mybets' && 'gameinfo-tab-item-active'" @click="status = 'mybets'">My Bets</div>
      <div class="gameinfo-tab-item" :class="status === 'leaders' && 'gameinfo-tab-item-active'" @click="status = 'leaders'">Top 24h</div>
      <div class="gameinfo-tab-item" :class="status === 'stakers' && 'gameinfo-tab-item-active'" @click="status = 'stakers'">Pool</div>

    </div>
    <div class="gameinfo-table">
      <!-- <div class="gameinfo-title">{{
        status == 'players' ? 'Players' :
        status == 'stakers' ? 'Stakers' : 'Top 24h'}}</div> -->
      <PlayersTable v-if="status == 'players'" />
      <StakersTable v-if="status == 'stakers'" />
      <LeaderBoard v-if="status == 'leaders'" />
      <MyBets v-if="status== 'mybets'" />
    </div>
  </div>
</template>

<script>
import PlayersTable from '../PlayersTable';
import MyBets from '../MyBets';
import StakersTable from '../StakersTable';
import LeaderBoard from '../LeaderBoard';

export default {
  components: {
    PlayersTable,
    StakersTable,
    LeaderBoard,
    MyBets
  },
  data() {
    return {
      status: 'players'
    }
  }
}
</script>

<style scoped>
.gameinfo {
  margin-top: 20px;
}
.gameinfo-table {
  color: #ffffff;
  text-align: center;
  padding: 20px 5px 10px 5px;
  background: rgba(255, 255, 255, 0.17);
  min-height: 450px;
}

.gameinfo-tab {
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px 20px 0 0;
}

.gameinfo-tab-item {
  display: inline-block;
  text-align: center;
  width: 30%;
  font-size: 18px;
  color: #ffffff;
  padding: 10px 0 5px 0;
  opacity: 0.5;
  transition: 0.3s all;
  border-bottom: 2px solid transparent;
  cursor: pointer;
}

.gameinfo-tab-item-active {
  opacity: 1;
  border-bottom: 2px solid rgba(255, 255, 255, 0.7);
}

.gameinfo-title {
  display: inline-block;
  text-align: center;
  margin-top: 10px;
  font-size: 30px;
  color: #eeba27;
  padding: 10px 0;
}
</style>


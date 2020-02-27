pragma solidity 0.5.0;

import "./PoolContract.sol";
import "./SafeMath.sol";

contract IReferral {
  function set(address from, address to) public;
  function refOf(address to) public view returns (address);
  function reward(address addr) public payable;
}

contract MaxBetContract is PoolContract {
    using SafeMath for uint;

    struct Bet {
        uint index;
        uint number;
        bool isOver;
        uint amount;
        address payable player;
        uint round;
        uint luckyNumber;
        uint seed;
        bool isFinished;
    }

    struct PlayerAmount {
        uint totalBet;
        uint totalPayout;
    }

    // SETTING
    uint constant public NUMBER_BLOCK_OF_LEADER_BOARD = 43200;
    uint constant public MAX_LEADER_BOARD = 10;
    uint constant public HOUSE_EDGE = 2;
    uint public MINIMUM_BET_AMOUNT = 0.5 ether;
    uint public PRIZE_PER_BET_LEVEL = 10;
    uint public REWARD_FOR_REFERRAL = 1000; // 1 / 1000 (0.1%) of bet amount for referral. max 0.2%

    address payable public referralContract;

    // Just for display on app
    uint public totalBetOfGame = 0;
    uint public totalWinAmountOfGame = 0;

    // Properties for game
    uint[] public commitments;
    Bet[] public bets; // All bets of player
    mapping(address => uint[]) public betsOf; // Store all bet of player
    mapping(address => PlayerAmount) public amountOf; // Store all bet of player

    mapping(address => bool) public croupiers;

    // Preperties for leader board
    uint[] public leaderBoardRounds; // block will sent prize
    mapping(uint => mapping(address => uint)) public totalBetOfPlayers; //Total bet of player in a round of board: leaderBoardBlock => address => total amount
    mapping(uint => address[]) public leaderBoards; //Leader board of a round of board: leaderBoardBlock => array of top players
    mapping(uint => mapping(address => uint)) public leaderBoardWinners; // round => player => prize

    event TransferWinner(address winner, uint betIndex, uint amount);
    event TransferLeaderBoard(address winner, uint round, uint amount);
    event NewBet(address player, uint round, uint index, uint number, bool isOver, uint amount);
    event DrawBet(address player, uint round, uint index, uint number, bool isOver, uint amount, bool isFinished, uint luckyNumber);

    constructor(address payable _operator, address _croupier) public {
        operator = _operator;
        croupiers[_croupier] = true;
        leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);

        bets.push(Bet({
            number: 0,
            isOver: false,
            amount: 0,
            player: address(0x0),
            round: 0,
            isFinished: true,
            luckyNumber: 0,
            index: 0,
            seed: 0
        }));
    }

    modifier onlyCroupier() { require(croupiers[msg.sender], "not croupier"); _; }

    /**
    GET FUNCTION
     */

    function getLastBetIndex(address add) public view returns (uint) {
        if (betsOf[add].length == 0) return 0;
        return betsOf[add][betsOf[add].length - 1];
    }

    function getCurrentLeaderBoard() public view returns (uint currentRound, address[] memory players) {
        currentRound = leaderBoardRounds[leaderBoardRounds.length - 1];
        players = leaderBoards[leaderBoardRounds[leaderBoardRounds.length - 1]];
    }

    function getRoundLeaderBoard(uint index, bool isFromTail) public view returns (uint) {
        if (isFromTail) {
            return leaderBoardRounds[leaderBoardRounds.length - index - 1];
        }
        else {
            return leaderBoardRounds[index];
        }
    }

    function totalNumberOfBets(address player) public view returns(uint) {
        if (player != address(0x00)) return betsOf[player].length;
        else return bets.length;
    }

    function numberOfCommitment() public view returns(uint) {
        return commitments.length;
    }

    function numberOfLeaderBoardRounds() public view returns (uint) {
        return leaderBoardRounds.length;
    }

    /**
    BET RANGE
     */

    function calculatePrizeForBet(uint betAmount) public view returns (uint) {
        uint bal = super.balanceForGame(betAmount);
        uint prize = 1 ether;
        if      (bal > 1000000 ether) prize = 500 ether;
        else if (bal >  500000 ether) prize = 200 ether;
        else if (bal >  200000 ether) prize = 100 ether;
        else if (bal >   50000 ether) prize =  50 ether;
        else if (bal >   20000 ether) prize =  20 ether;
        else if (bal >    2000 ether) prize =  10 ether;
        else                          prize =   5 ether;

        if (PRIZE_PER_BET_LEVEL < 10) return prize;
        else return prize.mul(PRIZE_PER_BET_LEVEL).div(10);
    }

    function betRange(uint number, bool isOver, uint amount) public view returns (uint min, uint max) {
        uint currentWinChance = calculateWinChance(number, isOver);
        uint prize = calculatePrizeForBet(amount);
        min = MINIMUM_BET_AMOUNT;
        max = prize.mul(currentWinChance).div(100);
        max = max > MINIMUM_BET_AMOUNT ? max : MINIMUM_BET_AMOUNT;
    }

    /**
    BET
     */

    function calculateWinChance(uint number, bool isOver) private pure returns (uint) {
        return isOver ? 99 - number : number;
    }

    function calculateWinAmount(uint number, bool isOver, uint amount) private pure returns (uint) {
        return amount.mul(100 - HOUSE_EDGE).div(calculateWinChance(number, isOver));
    }

    function addToLeaderBoard(address player, uint amount) private {
        uint round = leaderBoardRounds[leaderBoardRounds.length - 1];
        address[] storage boards = leaderBoards[round];
        mapping(address => uint) storage totalBets = totalBetOfPlayers[round];

        totalBets[player] = totalBets[player].add(amount);
        if (boards.length == 0) {
            boards.push(player);
        }
        else {
            // If found the player on list, set minIndex = MAX_LEADER_BOARD as a flag
            // to check it. if not found the play on array, minIndex is always
            // less than MAX_LEADER_BOARD
            uint minIndex = 0;
            for (uint i = 0; i < boards.length; i++) {
                if (boards[i] == player) {
                    minIndex = MAX_LEADER_BOARD;
                    break;
                } else if (totalBets[boards[i]] < totalBets[boards[minIndex]]) {
                    minIndex = i;
                }
            }
            if (minIndex < MAX_LEADER_BOARD) {
                if (boards.length < MAX_LEADER_BOARD) {
                    boards.push(player);
                } else if (totalBets[boards[minIndex]] < totalBets[player]) {
                    boards[minIndex] = player;
                }
            }
        }
    }

    /**
    DRAW WINNER
    */

    function checkWin(uint number, bool isOver, uint luckyNumber) private pure returns (bool) {
         return (isOver && number < luckyNumber) || (!isOver && number > luckyNumber);
    }

    function getLuckyNumber(uint betIndex, uint secret) private view returns (uint) {
        Bet memory bet = bets[betIndex];

        if(bet.round >= block.number) return 0;
        if (secret == 0) {
            if (block.number - bet.round < 1000) return 0;
        }
        else {
            uint commitment = commitments[betIndex];
            if (uint(keccak256(abi.encodePacked((secret)))) != commitment) {
                return 0;
            }
        }

        uint blockHash = uint(blockhash(bet.round));
        if (blockHash == 0) {
            blockHash = uint(blockhash(block.number - 1));
        }
        return 100 + ((secret ^ bet.seed ^ blockHash) % 100);
    }

    /**
    WRITE & PUBLIC FUNCTION
     */

    function login(address ref) external notContract {
        if (referralContract != address(0x0)) {
            IReferral(referralContract).set(ref, msg.sender);
        }

        accounts[msg.sender] = block.number;
    }

    function placeBet(uint number, bool isOver, uint seed) public payable notStopped isLogon notContract {
        (uint minAmount, uint maxAmount)= betRange(number, isOver, msg.value);
        uint index = bets.length;

        require(commitments.length > index);
        require(minAmount > 0 && maxAmount > 0);
        require(isOver ? number >= 4 && number <= 98 : number >= 1 && number <= 95);
        require(minAmount <= msg.value && msg.value <= maxAmount);
        require(bets[getLastBetIndex(msg.sender)].isFinished);

        uint winAmount = calculateWinAmount(number, isOver, msg.value);
        super.newBet(msg.value, winAmount);

        totalBetOfGame += msg.value;

        betsOf[msg.sender].push(index);

        bets.push(Bet({
            index: index,
            number: number,
            isOver: isOver,
            amount: msg.value,
            player: msg.sender,
            round: block.number,
            isFinished: false,
            luckyNumber: 0,
            seed: seed
            }));
        emit NewBet(msg.sender, block.number, index, number, isOver, msg.value);
    }

    function refundBet(address payable add) external onlyOperator {
        uint betIndex = getLastBetIndex(add);
        Bet storage bet = bets[betIndex];
        require(!bet.isFinished && bet.player == add && block.number - bet.round > 100000);

        uint winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount);

        add.transfer(bet.amount);
        super.finishBet(bet.amount, winAmount);

        bet.isFinished = true;
        bet.amount = 0;
    }

    function sendPrizeToWinners(uint round, address payable win1, address payable win2, address payable win3) private {
        if (win1 == address(0x00)) return;

        uint prize1 = 0;
        uint prize2 = 0;
        uint prize3 = 0;

        if (win3 != address(0x00)) prize3 = totalPrize.mul(2).div(10);
        if (win2 != address(0x00)) prize2 = totalPrize.mul(3).div(10);
        prize1 = totalPrize.sub(prize2).sub(prize3);

        if (prize3 > 0) {
            super.sendPrizeToWinner(win3, prize3);
            leaderBoardWinners[round][win3] = prize3;
            emit TransferLeaderBoard(win3, round, prize3);
        }
        if (prize2 > 0) {
            super.sendPrizeToWinner(win2, prize2);
            leaderBoardWinners[round][win2] = prize2;
            emit TransferLeaderBoard(win2, round, prize2);
        }
        super.sendPrizeToWinner(win1, prize1);
        emit TransferLeaderBoard(win1, round, prize1);
        leaderBoardWinners[round][win1] = prize1;

    }

    function finishLeaderBoard() public {
        uint round = leaderBoardRounds[leaderBoardRounds.length - 1];
        address[] storage boards = leaderBoards[round];
        mapping(address => uint) storage totalBets = totalBetOfPlayers[round];

        if (round > block.number) return;
        if (boards.length == 0) return;

        if (totalPrize <= 0) {
            leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);
            return;
        }

        // boards have maximum 3 elements.
        for (uint i = 0; i < boards.length; i++) {
            for (uint j = i + 1; j < boards.length; j++) {
                if (totalBets[boards[j]] > totalBets[boards[i]]) {
                    address temp = boards[i];
                    boards[i] = boards[j];
                    boards[j] = temp;
                }
            }
        }

        address w1 = boards[0];
        address w2 = boards.length > 1 ? boards[1] : address(0x00);
        address w3 = boards.length > 2 ? boards[2] : address(0x00);

        sendPrizeToWinners(round,
            address(uint160(w1)),
            address(uint160(w2)),
            address(uint160(w3)));
        leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);
    }

    /**
    FOR OPERATOR
     */

    function settleBet(uint i, uint secret, uint newCommitment) public onlyCroupier {
        require(i < bets.length);

        Bet storage bet = bets[i];

        require(bet.round < block.number);
        require(!bet.isFinished);

        commit(newCommitment);

        uint luckyNum = getLuckyNumber(bet.index, secret);
        require(luckyNum > 0);

        luckyNum -= 100;

        uint winAmount = calculateWinAmount(bet.number, bet.isOver, bet.amount);

        bet.luckyNumber = luckyNum;
        bet.isFinished = true;

        addToLeaderBoard(bet.player, bet.amount);
        if (referralContract != address(0x0)) {
            address ref = IReferral(referralContract).refOf(bet.player);
            if (ref != address(0x0)) {
                IReferral(referralContract).reward.value(bet.amount / REWARD_FOR_REFERRAL)(ref);
            }
        }

        if (checkWin(bet.number, bet.isOver, luckyNum)) {
            totalWinAmountOfGame += winAmount;
            bet.player.transfer(winAmount);
            amountOf[bet.player].totalBet += bet.amount;
            amountOf[bet.player].totalPayout += winAmount;
            emit TransferWinner(bet.player, bet.index, winAmount);
        } else {
            amountOf[bet.player].totalBet += bet.amount;
        }
        super.finishBet(bet.amount, winAmount);
        super.shareProfitForPrize(bet.amount);
        emit DrawBet(bet.player, bet.round, bet.index, bet.number, bet.isOver, bet.amount, bet.isFinished, bet.luckyNumber);
    }

    function commit(uint _commitment) public onlyCroupier {
        require(0 != _commitment);
        require(0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563 != _commitment);
        commitments.push(_commitment);
    }

    function addCroupier(address add) external onlyOperator {
        croupiers[add] = true;
    }

    function removeCroupier(address add) external onlyOperator {
        croupiers[add] = false;
    }

    function setPrizeLevel(uint level) external onlyOperator {
        require(PRIZE_PER_BET_LEVEL <= 1000);
        PRIZE_PER_BET_LEVEL = level;
    }

    function setMinBet(uint value) external onlyOperator {
        require(MINIMUM_BET_AMOUNT >= 0.1 ether);
        require(MINIMUM_BET_AMOUNT <= 10 ether);
        MINIMUM_BET_AMOUNT = value;
    }

    function setReferral(address payable _referral) external onlyOperator {
        referralContract = _referral;
    }

    function setRefferalReward(uint value) external onlyOperator {
        require(value >= 500); // 0.2%
        require(value <= 1000); // 0.1%
        REWARD_FOR_REFERRAL = value;
    }
}
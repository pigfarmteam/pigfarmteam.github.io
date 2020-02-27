pragma solidity 0.5.0;

import "./SafeMath.sol";

contract TRC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoolContract {
    using SafeMath for uint;

    uint constant public WITHDRAW_FEE = 10 ether;
    uint constant public MAX_STAKER_IN_POOL = 20;
    uint constant public MIN_STAKE_AMOUNT = 500 ether;
    uint constant public NUMBER_BLOCK_OF_TAKE_REVENUE = 900;

    uint public PERCENT_OF_REVENUE_FOR_OPERATOR = 10;
    uint public PERCENT_OF_REVENUE_FOR_LEADER_BOARD = 1000; // 1/1000 (0.1%) of bet amount for leader board, max 0.2%

    struct Stake {
        uint amount;
        bool isInPool;
        uint totalStake;
        uint profit;
    }

    bool public stopped = false;

    //the address used for receiving withdrawing fee
    address payable public operator;
    address private newOperator;

    uint public balanceOfOperator = 0;     // Cannot use for bet
    uint public balanceOfStakerOut = 0;    // Cannot use for bet
    uint public balanceOfBet = 0;          // Total balance of are not finished
    uint public lockBalanceForGame = 0;    // Don't use share value
    uint public totalPrize = 0;            // Cannot use for bet, totalPrize for leader board


    // This store all of stakers and their current amount in the contract
    // contain both in/out of pool
    mapping(address => Stake) public stakes;
    address[] public stakersInPool;
    address[] public stakers;
    uint public takeProfitAtBlock = 0;

    mapping(address => uint) public accounts;

    event NewStake(address staker, uint amount);
    event QuitPool(address staker, uint amount);
    event Distribute(uint blockNumber, uint pool, uint totalProfitOrLoss, bool isLoss, address staker, uint stakeAmount, uint profitOrLoss);

    constructor() public {
        takeProfitAtBlock = block.number + NUMBER_BLOCK_OF_TAKE_REVENUE;
    }

    /**
    MODIFIER
     */

    modifier onlyOperator() { require(operator == msg.sender, "only operator can do this action"); _; }
    modifier notStopped() { require(!stopped, "stopped"); _; }
    modifier isStopped() { require(stopped, "not stopped"); _; }
    modifier isLogon() {
        require(accounts[msg.sender] > 0);
        require(block.number > accounts[msg.sender]);
        _;
    }
    modifier notContract() {
        uint size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0);
        require(tx.origin == msg.sender);
        _;
    }

    /**
    GET FUNCTION
     */

    function getStakersInPool() public view returns (address[] memory) { return stakersInPool; }

    function getStakers() public view returns (address[] memory) { return stakers; }

    function getMinAmountForJoin(address add) public view returns (uint) {
        if (stakes[add].isInPool) return MIN_STAKE_AMOUNT;
        if (stakersInPool.length < MAX_STAKER_IN_POOL) return MIN_STAKE_AMOUNT;

        uint index = findIndexOfMinStakeInPool();
        if (stakes[stakersInPool[index]].amount > stakes[add].amount) {
            return (2 + uint((stakes[stakersInPool[index]].amount - stakes[add].amount) / MIN_STAKE_AMOUNT)) * MIN_STAKE_AMOUNT;
        }
        else {
            return MIN_STAKE_AMOUNT;
        }
    }

    function poolState() private view returns (uint pool, uint profit) {
        for (uint i = 0; i < stakersInPool.length; i++) {
            address add = stakersInPool[i];
            Stake memory stake = stakes[add];
            pool = pool.add(stake.amount);
            profit = profit.add(stake.profit);
        }
    }

    function balanceForGame(uint subAmount) public view returns (uint) {
        uint pool;
        uint profit;
        (pool, profit) = poolState();
        uint bal = address(this).balance
            .sub(subAmount)
            .sub(balanceOfOperator + balanceOfStakerOut)
            .sub(balanceOfBet)
            .sub(totalPrize + profit);
        return pool > bal ? bal : pool;
    }

    /**
    JOIN/QUIT POOL
     */

    function findIndexOfMinStakeInPool() private view returns (uint) {
        require(stakersInPool.length > 0);

        uint min = 0;
        for (uint i = 1; i < stakersInPool.length; i++) {
            if (stakes[stakersInPool[i]].amount < stakes[stakersInPool[min]].amount) {
                min = i;
            }
        }

        return min;
    }

    function updateStake(address add, uint value) private {
        Stake storage stake = stakes[add];
        stake.amount = stake.amount.add(value);
        stake.totalStake = stake.totalStake.add(value);
    }

    function removeFromPool(address staker) private {
        Stake storage stake = stakes[staker];
        if (stake.isInPool) {
            stake.amount = stake.amount.add(stake.profit);
            stake.profit = 0;
            balanceOfStakerOut = balanceOfStakerOut.add(stake.amount);

            stake.isInPool = false;

            for (uint i = 0; i < stakersInPool.length; i++) {
                if (stakersInPool[i] == staker) {
                    stakersInPool[i] = stakersInPool[stakersInPool.length - 1];
                    stakersInPool.pop();
                    break;
                }
            }
        }
    }

    function addToPool(address add, uint appendAmount) private {
        Stake storage stake = stakes[add];

        if (stake.isInPool || stakersInPool.length >= MAX_STAKER_IN_POOL) return;

        if (stake.amount > appendAmount && !stake.isInPool) {
            uint oldAmount = stake.amount.sub(appendAmount);
            balanceOfStakerOut = balanceOfStakerOut.sub(oldAmount);
        }

        stake.isInPool = true;
        stakersInPool.push(add);
    }

    function refundForStaker(address payable staker) private {
        Stake storage stake = stakes[staker];
        require(!stake.isInPool, "Cannot refund");
        require(stake.amount > 0 || stake.profit > 0, "Cannot refund");

        balanceOfStakerOut = balanceOfStakerOut.sub(stake.amount);

        uint transferAmount = stake.amount;
        if (transferAmount > stake.totalStake) {
            uint totalProfit = transferAmount.sub(stake.totalStake);
            uint forOperator =  totalProfit.mul(PERCENT_OF_REVENUE_FOR_OPERATOR).div(100);
            transferAmount = transferAmount.sub(forOperator);
            balanceOfOperator = balanceOfOperator.add(forOperator);
        }

        if (transferAmount > WITHDRAW_FEE) {
            transferAmount = transferAmount.sub(WITHDRAW_FEE);
            balanceOfOperator = balanceOfOperator.add(WITHDRAW_FEE);
        }

        resetStake(staker);
        staker.transfer(transferAmount);
    }

    function resetStake(address staker) private {
        Stake storage stake = stakes[staker];
        stake.amount = 0;
        stake.totalStake = 0;
        stake.profit = 0;
        stake.isInPool = false;
    }

    /**
    FOR GAME
     */

    function newBet(uint betAmount, uint winAmount) internal {
        require(lockBalanceForGame.add(winAmount) < balanceForGame(betAmount), "Balance is not enough for game");
        lockBalanceForGame = lockBalanceForGame.add(winAmount);
        balanceOfBet = balanceOfBet.add(betAmount);
    }

    function finishBet(uint betAmount, uint winAmount) internal {
        lockBalanceForGame = lockBalanceForGame.sub(winAmount);
        balanceOfBet = balanceOfBet.sub(betAmount);
    }

    /**
    DISTRIBUTE PROFIT
     */

    function calculateAmountStake(address staker) private {
        Stake storage stake = stakes[staker];

        if (stake.totalStake <= stake.amount) return;

        uint loss = stake.totalStake.sub(stake.amount);
        uint coverLoss = loss >= stake.profit ? stake.profit : loss;

        stake.amount = stake.amount.add(coverLoss);
        stake.profit = stake.profit.sub(coverLoss);
    }

    function distributeLoss(uint pool, uint poolLoss) private {
        uint restOfLoss = poolLoss;
        uint n = stakersInPool.length;
        for (uint i = 0; i < n; i++) {
            Stake storage stake = stakes[stakersInPool[i]];
            uint loss = i == n - 1 ? restOfLoss : poolLoss.mul(stake.amount).div(pool);
            restOfLoss = restOfLoss.sub(loss);

            emit Distribute(block.number, pool, poolLoss, true, stakersInPool[i], stake.amount, loss);

            if (loss <= stake.amount) {
                stake.amount = stake.amount.sub(loss);
            }
            else {
                uint takeFromProfit = loss - stake.amount;
                stake.amount = 0;
                stake.profit = takeFromProfit <= stake.profit ? stake.profit.sub(takeFromProfit) : 0;
            }

            calculateAmountStake(stakersInPool[i]);
        }
    }

    function distributeProfit(uint pool, uint poolProfit) private {
        uint restOfProfit = poolProfit;
        uint n = stakersInPool.length;
        for (uint i = 0; i < n; i++) {
            Stake storage stake = stakes[stakersInPool[i]];
            uint profit = i == n - 1 ? restOfProfit : poolProfit.mul(stake.amount).div(pool);
            restOfProfit = restOfProfit.sub(profit);

            emit Distribute(block.number, pool, poolProfit, false, stakersInPool[i], stake.amount, profit);

            stake.profit = stake.profit.add(profit);
            calculateAmountStake(stakersInPool[i]);
        }
    }

    function takeProfitInternal(bool force, uint subAmount) internal {
        if (!force && (takeProfitAtBlock >= block.number || stakersInPool.length == 0)) {
            return;
        }
        if (stopped) {
            return;
        }
        takeProfitAtBlock = block.number + NUMBER_BLOCK_OF_TAKE_REVENUE;
        (uint pool, uint profit) = poolState();

        uint currentPool = address(this).balance
            .sub(subAmount)
            .sub(balanceOfOperator + balanceOfStakerOut)
            .sub(balanceOfBet)
            .sub(totalPrize + profit);

        if (currentPool > pool) {
            distributeProfit(pool, currentPool - pool);
        }
        else if (currentPool < pool) {
            distributeLoss(pool, pool - currentPool);
        }
    }

    function shareProfitForPrize(uint amount) internal {
        uint prize = amount.div(PERCENT_OF_REVENUE_FOR_LEADER_BOARD);
        totalPrize = totalPrize.add(prize);
    }

    function sendPrizeToWinner(address payable winner, uint amount) internal {
        if (winner == address(0x00)) return;
        if (amount > totalPrize) return;
        totalPrize = totalPrize.sub(amount);
        winner.transfer(amount);
    }

    /**
    FOR POOL
     */

    function quitPool() external isLogon notContract {
        address payable staker = msg.sender;
        Stake storage stake = stakes[staker];
        if (stake.amount == 0) return;

        if (!stake.isInPool || stopped) {
            refundForStaker(staker);
        }
        else {
            takeProfitInternal(true, 0);
            removeFromPool(staker);
            refundForStaker(staker);
        }
    }

    function joinPool() external payable notStopped isLogon notContract  {
        address staker = msg.sender;
        uint amount = msg.value;
        Stake storage stake = stakes[staker];

        require(amount >= getMinAmountForJoin(staker), "Not enought amount to join pool");

        stakers.push(staker);
        takeProfitInternal(true, amount);
        updateStake(staker, amount);

        if (stake.isInPool) return;
        if (stakersInPool.length >= MAX_STAKER_IN_POOL) {
            uint indexOfMinStake = findIndexOfMinStakeInPool();
            removeFromPool(stakersInPool[indexOfMinStake]);
        }
        addToPool(staker, amount);

        emit NewStake(staker, amount);
    }

    function rejoinPool(address add) external notStopped isLogon notContract {
        address staker = add == address(0x00) ? msg.sender : add;
        Stake storage stake = stakes[staker];
        require(stake.amount > 0, "don't have amount");
        require(!stake.isInPool, "in pool already");

        uint indexOfMinStake;

        if (stakersInPool.length < MAX_STAKER_IN_POOL) {
            require(stake.amount >= MIN_STAKE_AMOUNT, 'Your stake is too low');
        }
        else {
            indexOfMinStake = findIndexOfMinStakeInPool();
            Stake memory minStake = stakes[stakersInPool[indexOfMinStake]];
            require(minStake.amount < stake.amount, "Not enought amount to join pool");
        }

        takeProfitInternal(true, 0);
        if (stakersInPool.length >= MAX_STAKER_IN_POOL) {
            removeFromPool(stakersInPool[indexOfMinStake]);
        }
        addToPool(staker, 0);
        emit NewStake(staker, 0);
    }

    function withdrawProfit() external isLogon notContract {
        Stake storage stake = stakes[msg.sender];
        require(stake.profit > 0, "Don't have profit");
        uint transferAmount = stake.profit.mul(100 - PERCENT_OF_REVENUE_FOR_OPERATOR).div(100);
        balanceOfOperator = balanceOfOperator.add(stake.profit).sub(transferAmount);
        stake.profit = 0;
        msg.sender.transfer(transferAmount);
    }

    /**
    OPERATOR
     */

    function setRevenueForOperator(uint value) external onlyOperator {
        require(value >= 1);
        require(value <= 15);
        PERCENT_OF_REVENUE_FOR_OPERATOR = value;
    }

    function setPrizeForLeaderBoard(uint value) external onlyOperator {
        require(value >= 500); // 0.2%
        require(value <= 1000); // 0.1%
        PERCENT_OF_REVENUE_FOR_LEADER_BOARD = value;
    }

    function takeProfit() external {
        takeProfitInternal(false, 0);
    }

    function operatorWithdraw(address payable add, uint amount) external onlyOperator {
        require (amount <= balanceOfOperator, "Invalid amount");
        balanceOfOperator = balanceOfOperator.sub(amount);
        add.transfer(amount);
    }

    function () external payable {
        balanceOfOperator = balanceOfOperator.add(msg.value);
    }

    function emergencyToken(TRC20 token, uint amount) external onlyOperator {
        token.transfer(operator, amount);
    }

    function prizeForLeaderBoard() external payable {
        totalPrize = totalPrize.add(msg.value);
    }

    function changeOperator(address add) external onlyOperator {
        newOperator = add;
    }

    function confirmChangeOperator() external {
        require(msg.sender == newOperator, "Invalid sender");
        operator = address(uint160(newOperator));
        newOperator = address(0x00);
    }

    function removeStaker(uint i) external {
        address staker = stakers[i];
        Stake storage stake = stakes[staker];
        require(stake.amount == 0 && stake.profit == 0, "Cannot remove");
        resetStake(staker);
        stakers[i] = stakers[stakers.length - 1];
        stakers.pop();
    }

    function removeDuplicateStaker(uint i, uint j) external {
        require(i != j, "Same element");
        require(stakers[i] == stakers[j], "diffirent address");
        stakers[j] = stakers[stakers.length - 1];
        stakers.pop();
    }

    /** FOR EMERGENCY */

    function prepareStopGame(uint confirm, bool isStopNow) external onlyOperator {
        require(confirm == 0x1, "Enter confirm code");
        takeProfitInternal(true, 0);
        for (uint i = 0; i < MAX_STAKER_IN_POOL && stakersInPool.length > 0; i++) {
            removeFromPool(stakersInPool[0]);
        }
        stopped = isStopNow ? true : stopped;
    }

    function forceStopGame(uint confirm) external onlyOperator {
        require(confirm == 0x1, "Enter confirm code");
        stopped = true;
    }

    function forceRefundForStaker(address payable staker) external onlyOperator isStopped {
        Stake storage stake = stakes[staker];
        staker.transfer(stake.amount + stake.profit);
        resetStake(staker);
    }

    function withdrawAllBalanceAfterRefundForAllStaker() external onlyOperator isStopped {
        uint sum = 0;
        for (uint i = 0; i < stakers.length; i++) {
            sum += stakes[stakers[i]].amount;
            sum += stakes[stakers[i]].profit;
        }
        if (sum == 0) {
            operator.transfer(address(this).balance);
        }
    }
}
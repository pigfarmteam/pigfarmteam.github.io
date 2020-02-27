pragma solidity 0.5.0;

contract ReferralContract {
  mapping(address => address) public referral;
  mapping(address => bool) public games;
  mapping(address => uint) public rewards;
  mapping(address => address[]) public referralOf;
  address public owner;
  address public newOwner;
  uint public lastWithdraw;

  modifier inGame() {
    require(games[msg.sender]);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address _owner) public {
    owner = _owner;
    lastWithdraw = block.number;
  }

  function addGame(address game) public onlyOwner {
    games[game] = true;
  }

  function removeGame(address game) public onlyOwner {
    games[game] = false;
  }

  function transferOwner(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function confrimTransfer() public {
    require(msg.sender == newOwner);
    owner = newOwner;
  }

  function set(address from, address to) public inGame {
    if (from != address(0x0)
      && to != address(0x0)
      && from != to
      && referral[to] == address(0x0)
    ) {
      referral[to] = from;
      referralOf[from].push(to);
    }
  }

  function refOf(address to) public view returns (address) {
    return referral[to];
  }

  function numberReferralOf(address add) public view returns (uint) {
    return referralOf[add].length;
  }

  function reward(address addr) public payable inGame {
    if (addr != address(0x0)) {
      address ref = refOf(addr);
      if (ref != address(0x0)) {
        uint amountForRef = msg.value / 20;
        rewards[ref] += amountForRef;
        rewards[addr] += (msg.value - amountForRef);
      }
      else {
        rewards[addr] += msg.value;
      }
    }
  }

  function withdraw() public {
    require(rewards[msg.sender] > 0);
    uint transferAmount = rewards[msg.sender];
    rewards[msg.sender] = 0;
    lastWithdraw = block.number;
    msg.sender.transfer(transferAmount);
  }

  function withdrawAll() public onlyOwner {
    // Owner can withdraw all balance if in 1 year dont have any one withdraw;
    require(block.number - lastWithdraw > 17520000);
    msg.sender.transfer(address(this).balance);
  }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TMSAFToken is IERC20, Ownable, ReentrancyGuard {
  uint256 private _totalSupply;
  uint256 private _currentPriceOption;
  uint256 private _tokenPrice = 1;
  uint256 private _votingStartedTime;
  uint256 private _votingNumber;
  uint256 private _timeToVote = 1 days;
  uint256 public feePercentage = 5;
  uint256 private _accumulatedFees;
  uint256 public feeBurnTime = 7 days;
  uint256 public lastFeeBurnTime;
  uint256[] private _votedPrices;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _votingPower;
  mapping(address => uint256) private _userVotesForPrice;
  mapping(uint256 => uint256) private _powerOfPrice;

  event VotingStarted(uint256 votingNumber, uint256 startTime);
  event VotingEnded(uint256 votingNumber, uint256 _tokenPrice);
  event TokensBought(address indexed buyer, uint256 amount, uint256 totalCost);
  event TokensSold(address indexed seller, uint256 amount, uint256 totalEarned);

  constructor() {
    _mint(msg.sender, 999);
  }

  function _mint(address account, uint256 amount) internal onlyOwner {
    require(amount > 0, "amount must be greater than 0");

    _balances[account] += amount;
    _totalSupply += amount;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    require(
      _balances[msg.sender] >= amount,
      "must have a balance of at least amount"
    );
    require(to != address(0), "sender cannot be the zero address");

    _balances[msg.sender] -= amount;
    _balances[to] += amount;

    _updateVotingPower(msg.sender);
    _updateVotingPower(to);

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    require(sender != address(0), "Sender address cannot be zero");

    _allowances[sender][msg.sender] -= amount;
    _balances[sender] -= amount;
    _balances[recipient] += amount;

    _updateVotingPower(sender);
    _updateVotingPower(recipient);

    emit Transfer(sender, recipient, amount);

    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view returns (uint256) {
    require(owner != address(0), "Owner address cannot be zero");
    require(spender != address(0), "Spender address cannot be zero");

    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  modifier isAbleToVote() {
    require(
      (_balances[msg.sender] * 10000) / _totalSupply > 5,
      "Voter should have more than 0.05% of total token supply"
    );
    require(_balances[msg.sender] > 0, "Voter should have at least one token");
    require(_votingStartedTime > 0, "Voting has not started yet");
    _;
  }

  // make able to vote only if more than 0.05% ot total. Can vote for existing, but cannot vote his own
  function vote(uint256 price) external isAbleToVote {
    require(price > 0, "Price should be more than 0");

    uint256 voterVotingPower = _votingPower[msg.sender];
    _powerOfPrice[price] += voterVotingPower;
    _userVotesForPrice[msg.sender] = price;

    // works if its the first vote
    if (_powerOfPrice[price] == voterVotingPower) {
      _votedPrices.push(price);
    }
  }

  function buy() external payable {
    require(msg.value >= _tokenPrice, "Insufficient ether sent to buy tokens");
    uint256 amount = msg.value / _tokenPrice;
    uint256 feeAmount = (amount * feePercentage) / 10000;
    uint256 netAmount = amount - feeAmount;

    _balances[msg.sender] += netAmount;
    _totalSupply += netAmount;

    _accumulatedFees += feeAmount;
    _updateVotingPower(msg.sender);

    emit TokensBought(msg.sender, netAmount, msg.value);
  }

  function sell(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot sell zero tokens");
    require(_balances[msg.sender] >= amount, "Not enough to sell");

    uint256 sellAmount = amount * _tokenPrice;
    _balances[msg.sender] -= amount;
    _totalSupply -= amount;

    _updateVotingPower(msg.sender);

    emit TokensSold(msg.sender, amount, sellAmount);

    payable(msg.sender).transfer(sellAmount);
  }

  function startVoting() external {
    require(_votingStartedTime == 0, "Voting has already started");
    _votingStartedTime = block.timestamp;
    _votingNumber++;

    emit VotingStarted(_votingNumber, _votingStartedTime);
  }

  function endVoting() external {
    require(_votingStartedTime > 0, "Voting has not started yet");
    require(
      block.timestamp >= _votingStartedTime + _timeToVote,
      "Voting period has not ended yet"
    );

    uint256 maxVotingPower = 0;
    uint256 winningPrice = _tokenPrice;

    for (uint256 i = 0; i < _votedPrices.length; i++) {
      uint256 votedPrice = _votedPrices[i];
      uint256 totalPowerOfPrice = _powerOfPrice[votedPrice];

      if (totalPowerOfPrice > maxVotingPower) {
        maxVotingPower = totalPowerOfPrice;
        winningPrice = votedPrice;
      }
    }

    _tokenPrice = winningPrice;

    _votingStartedTime = 0;
    _votingNumber++;

    delete _votedPrices;

    emit VotingEnded(_votingNumber, _tokenPrice);
  }

  function burn(address account, uint256 amount) internal {
    require(account != address(0), "Burn from the zero address");
    require(_balances[account] >= amount, "must have at least amount tokens");

    _balances[account] -= amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function burnFromOwner(uint256 amount) external onlyOwner {
    burn(msg.sender, amount);
  }

  function _updateVotingPower(address account) internal {
    uint256 voterVotingPower = _votingPower[account];
    uint256 votedPrice = _userVotesForPrice[account];

    if (votedPrice > 0) {
      _powerOfPrice[votedPrice] -= voterVotingPower;
      _votingPower[account] = _balances[account];
      _powerOfPrice[votedPrice] += _votingPower[account];
    } else {
      _votingPower[account] = _balances[account];
    }
  }

  function getVotingPower(uint256 price) external view returns (uint256) {
    return _powerOfPrice[price];
  }

  function getTokenPrice() external view returns (uint256) {
    return _tokenPrice;
  }

  function getUserVoteForPrice(address user) external view returns (uint256) {
    return _userVotesForPrice[user];
  }

  function getVotingStartedTime() external view returns (uint256) {
    return _votingStartedTime;
  }
}

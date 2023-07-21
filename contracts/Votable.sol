// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {TMSAFToken} from "./TMSAFToken.sol";

contract VotingContract is TMSAFToken {
  event VotingStarted(uint256 votingNumber, uint256 startTime);
  event VotingEnded(uint256 votingNumber, uint256 _tokenPrice);

  uint256[] private _votedPrices;
  uint256 internal _votingStartedTime;
  uint256 internal _votingNumber;
  uint256 internal _timeToVote = 1 days;
  uint256 public totalVotesCount;
  uint256 public priceOption = _tokenPrice;
  uint256 public amountToBurn;

  struct Vote {
    uint256 vote;
    uint256 power;
    address next;
    address prev;
  }

  address private _head;

  mapping(address => Vote) private votes;
  mapping(uint256 => address) private _isParticularPriceProposed;
  mapping(address => address) public voters;

  modifier isAbleToVote() {
    require(
      (_balances[msg.sender] * 10000) / _totalSupply > 5,
      "Voter should have more than 0.05% of total token supply"
    );
    require(_balances[msg.sender] > 0, "Voter should have at least one token");
    require(_votingStartedTime > 0, "Voting has not started yet");
    _;
  }

  function vote(
    uint256 price,
    address prev,
    address next
  ) external isAbleToVote {
    require(price > 0, "Price should be more than 0");

    address index = _isParticularPriceProposed[price];
    uint power = _votingPower[msg.sender];

    if (votes[index].vote == 0) {
      // if voter does not exist then we create one

      votes[msg.sender] = Vote(price, power, prev, next);

      sortNode(prev, next, msg.sender);
      totalVotesCount++; // make +1 for loop so we know the length of mapping
    } else {
      // if it exists, we add the power to the price he wanted
      votes[index].power += power;
      sortNode(prev, next, index);
    }
  }

  function _getAddressAtIndex(uint256 index) private view returns (address) {
    uint256 currentIndex = 0;
    address currentAddress;

    for (uint256 i = 0; i < totalVotesCount; i++) {
      if (votes[currentAddress].vote != 0) {
        if (currentIndex == index) {
          return currentAddress;
        }
        currentIndex++;
      }
    }

    return address(0);
  }

  function getPricesList()
    public
    view
    returns (address[] memory, Vote[] memory)
  {
    address[] memory addresses = new address[](totalVotesCount);
    Vote[] memory structs = new Vote[](totalVotesCount);

    uint256 currentIndex = 0;
    for (uint256 i = 0; i < totalVotesCount; i++) {
      address currentAddress = _getAddressAtIndex(i);
      Vote storage currentStruct = votes[currentAddress];
      addresses[currentIndex] = currentAddress;
      structs[currentIndex] = currentStruct;
      currentIndex++;
    }

    return (addresses, structs);
  }

  function sortNode(address prev, address next, address currentIndex) public {
    if (totalVotesCount == 0) {
      _head = currentIndex;
      votes[currentIndex].prev = prev;
      votes[currentIndex].next = next;

      votes[prev].next = currentIndex;
      votes[next].prev = currentIndex;
    } else if (votes[next].power == 0) {
      votes[currentIndex].prev = prev;
      votes[currentIndex].next = address(0);

      votes[prev].next = currentIndex;
    } else if (votes[prev].power == 0) {
      votes[currentIndex].next = next;
      votes[currentIndex].prev = address(0);

      votes[next].prev = currentIndex;
    } else if (
      votes[prev].power < votes[currentIndex].power &&
      votes[next].power > votes[currentIndex].power &&
      votes[prev].next == next
    ) {
      votes[currentIndex].prev = prev;
      votes[currentIndex].next = next;

      votes[prev].next = currentIndex;
      votes[next].prev = currentIndex;

      if (votes[next].power != 0) {
        if (votes[currentIndex].power > votes[_head].power) {
          _head = currentIndex;
        }
      }
    } else {
      revert("Wrong position");
    }
  }

  function buyTokens(
    address prev,
    address next,
    address currentIndex
  ) public payable {
    uint256 fee = (msg.value * feePercentage) / 100;
    uint256 purchaseAmount = (msg.value - fee) * priceOption;

    require(purchaseAmount > 0, "Insufficient payment");

    address voterAddress = msg.sender;

    _totalSupply += purchaseAmount;
    _balances[owner()] += fee;
    amountToBurn += fee;
    _balances[voterAddress] += purchaseAmount;

    if (votes[voterAddress].vote != 0) {
      sortNode(prev, next, currentIndex);
    }
  }

  function sellTokens(
    uint256 _amount,
    address prev,
    address next,
    address currentIndex
  ) public {
    require(_balances[msg.sender] >= _amount, "Insufficient balance");

    uint256 fee = (_amount * feePercentage) / 100;
    uint256 saleAmount = (_amount - fee) * priceOption;

    _balances[msg.sender] -= _amount;

    _totalSupply -= _amount;
    _balances[owner()] += fee;
    amountToBurn += fee;

    if (votes[msg.sender].vote != 0) {
      sortNode(prev, next, currentIndex);
    }

    payable(msg.sender).transfer(saleAmount);
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

    _tokenPrice = votes[_head].vote;

    emit VotingEnded(_votingNumber, _tokenPrice);
  }

  function getVotingPower(uint256 price) external view returns (uint256) {}

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

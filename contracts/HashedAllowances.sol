// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// add typechain hardhat typechain
// 1.set allowance to be hashed on contract
// 2.calculate all transactions offchain
// 3. hash the result
// 4. send hash to contract and check if its the same
// 5. if the same its true, then we can use source for transfer

// make gas report, with this 2 options. WHat is better?

contract TMSAFToken is IERC20, Ownable {
  uint256 private _totalSupply;

  mapping(address => uint256) private _balances;
  mapping(bytes32 => uint256) private _allowances;

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

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    require(
      _balances[msg.sender] >= amount,
      "must have a balance of at least amount"
    );
    require(to != address(0), "sender cannot be the zero address");

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    require(sender != address(0), "Sender address cannot be zero");

    _allowances[keccak256(abi.encodePacked(sender, msg.sender))] -= amount;
    _balances[recipient] += amount;
    _balances[msg.sender] -= amount;

    emit Transfer(sender, recipient, amount);

    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view returns (uint256) {
    require(owner != address(0), "Owner address cannot be zero");
    require(spender != address(0), "Spender address cannot be zero");

    return _allowances[keccak256(abi.encodePacked(owner, spender))];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _allowances[keccak256(abi.encodePacked(msg.sender, spender))] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TMSAFToken is IERC20, Ownable {
  uint256 private _totalSupply;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  constructor() {
    _mint(msg.sender, 999);
  }

  function _mint(address account, uint256 amount) internal onlyOwner {
    require(amount > 0, "Amount must be greater than 0");

    _balances[account] += amount;
    _totalSupply += amount;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    require(_balances[msg.sender] >= amount, "sender should have more money(");

    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool) {
    require(sender != address(0), "Sender address cannot be zero");

    _allowances[sender][msg.sender] -= amount;

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

  function approve(address spender, uint256 amount) public returns (bool) {
    _allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }
}

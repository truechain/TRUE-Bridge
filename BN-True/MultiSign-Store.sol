pragma solidity ^0.5.0;

import './MultiSign.sol';

contract MultiSignStore is MultiSign {
  mapping (address => uint256) internal balance;
  uint256 public fee = 1 ether;

  event Unlock (address indexed user, uint256 amount, uint256 fee);
  event Lock (address indexed user, bytes20 indexed bnaddress, uint256 amount);
  event UpdateFee (uint256 fee);

  // solium-disable-next-line no-empty-blocks
  constructor (uint256 _threshold, address[] memory _whiteList) MultiSign (address(this), _threshold, _whiteList) public {}

  function balanceOf (address _user) public view returns (uint256) {
    return balance[_user];
  }

  // 0x7eee288d
  function unlock (address payable _user, uint256 _amount) external needSuggest {
    _user.transfer(_amount);
    emit Unlock(_user, _amount, 0);
  }

  function recharge (bytes20 _bnaddress) external payable {
    uint256 actualFee = fee;
    if (msg.value < fee) {
      actualFee = msg.value;
    }
    uint256 part = actualFee / whiteListSize;
    for (uint256 i = 1; i <= whiteListSize; i++) {
      balance[whiteList[i]] += part;
    }
    emit Lock(msg.sender, _bnaddress, msg.value - actualFee);
  }

  // 0x69fe0e2d
  function setFee (uint256 _fee) external needSuggest {
    fee = _fee;
    emit UpdateFee(_fee);
  }

  function withdraw () external {
    uint256 value = balance[msg.sender];
    require(value > 0, "no balance");
    balance[msg.sender] = 0;
    msg.sender.transfer(value);
  }
}

pragma solidity ^0.5.7;

import "./MultiSign.sol";

interface ERC20 {
  function transfer (address, uint256) external;
}

contract MultiSignStore is MultiSign {
  ERC20 public token;

  address constant mainNetAddr = address(0xfFf0000000000000000000000000000000000000);
  
  mapping (address => uint256) internal balance;
  mapping(address=>mapping(address=>uint256)) internal _allBalance;
  uint256 public fee = 0.12 ether;

  event Unlock (address indexed user, uint256 amount, uint256 fee);
  event UpdateFee (uint256 fee);
  event Lock (address indexed user, uint256 amount);
  
  constructor (uint256 _threshold, address[] memory _whiteList) MultiSign (address(this), _threshold, _whiteList) public {
     
  }

  function balanceOf (address _user,address _coinAddr) public view returns (uint256) {
      return _allBalance[_user][_coinAddr];
  }

  // 0x7eee288d
  function unlock (address payable _user, uint256 _amount,address _coinAddr) external needSuggest {
    uint256 actualFee = fee;
    if (_amount > fee) {
        
        uint256 value = _amount - fee;
        if(_coinAddr == mainNetAddr) {
            _user.transfer(_amount);  
        }else{
            ERC20(_coinAddr).transfer(_user, value);
        }
    } else {
        actualFee = _amount;
    }
    address[] storage sign = pSign[tempPID];
    uint256 part = actualFee / sign.length;
    for (uint256 i = 0; i < sign.length; i++) {
        _allBalance[sign[i]][_coinAddr] += part;
    }
    emit Unlock(_user, _amount, actualFee);
  }
  
  function recharge ( ) external payable {
      emit Lock(msg.sender, msg.value);
  }

  // 0x69fe0e2d
  function setFee (uint256 _fee) external needSuggest {
      fee = _fee;
      emit UpdateFee(_fee);
  }

  function withdraw (address _coinAddr) external {
      uint256 value = _allBalance[msg.sender][_coinAddr];
      require(value > 0, "no balance");
      _allBalance[msg.sender][_coinAddr] = 0;
      ERC20(_coinAddr).transfer(msg.sender, value);
  }
}

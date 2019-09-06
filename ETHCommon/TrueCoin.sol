pragma solidity ^0.5.0;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
  }
}



contract TrueCoin {
  using SafeMath for uint256;

  string public  name ;
  string public  symbol ;
  uint256 public  decimals ;
  address payable public founder;
  uint256 public totalSupply;

  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  event Transfer (address indexed _from, address indexed _to, uint256 _value);
  event Approval (address indexed _owner, address indexed _spender, uint256 _value);

  constructor (string memory _name,string memory _symbol,uint256 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    founder = msg.sender;
  }

  function balanceOf (address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer (address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    require((balances[msg.sender] >= _value), "");
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success) {
    require (_to != address(0), "");
    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function safeApprove(address _spender, uint256 _fromValue, uint256 _toValue) public returns (bool success) {
    require(allowed[msg.sender][_spender] == _fromValue, "");
    allowed[msg.sender][_spender] = _toValue;
    emit Approval(msg.sender, _spender, _toValue);
    return true;
  }

  function allowance (address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function mint (address _to, uint256 _amount) public {
    require(msg.sender == founder, "");

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(address(this), _to, _amount);
  }

  function burn (uint256 _amount) public {
    require(balances[msg.sender] >= _amount, "");

    totalSupply = totalSupply.sub(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    
    TrueERCManager(founder).burnEvent(msg.sender,_amount);
    emit Transfer(msg.sender, address(this), _amount);
  }
}

contract TrueERCManager{
    
    address private _owner;
    address payable public founder;
    struct CoinInfo{
        address ci_oldContractAddr;
        string ci_Name;
        string ci_symbol;
        uint256 ci_decimals;
    }
    
    
    mapping(bytes32=>TrueCoin) public _erc20_terc20;
    mapping(address=>bytes32) public terc20_pid;
    mapping(address=>mapping(bytes32=>CoinInfo)) private _terc20_erc20; 
    mapping(bytes32=>CoinInfo) public _terc20Info;
    
    event MintContract (address indexed user, uint256 value,address tContractAddr);
    event BurnBalance (address indexed user, uint256 value,address OldContractAddr);
    
    constructor() public{
         founder = msg.sender;
         _owner = msg.sender;
    }
    
    function mint(string memory name,string memory symbol,uint256 decimals,address oldContracAddr,address to_, uint256 amount)
        public
    {
        require(msg.sender == founder,"only founder can ");
        bytes32 newContrHash = keccak256(abi.encodePacked(name,symbol,decimals,oldContracAddr)); 
        
        CoinInfo storage tInfo = _terc20Info[newContrHash];
        
        if (tInfo.ci_oldContractAddr == address(0)){
            // need create a new contract
            tInfo.ci_oldContractAddr = oldContracAddr;
            tInfo.ci_Name = name;
            tInfo.ci_symbol = symbol;
            tInfo.ci_decimals = decimals;
            _terc20Info[newContrHash] = tInfo;
            
            TrueCoin tcontract = new TrueCoin(name,symbol,decimals);
            _erc20_terc20[newContrHash] = tcontract;
            // need mint this
            tcontract.mint(to_,amount);
            
            _terc20_erc20[address(tcontract)][newContrHash] = tInfo;
            terc20_pid[address(tcontract)] = newContrHash;
            
            emit MintContract(to_,amount,address(tcontract));
           
        }else{
            // need mint 
            TrueCoin tcontract = _erc20_terc20[newContrHash];
            tcontract.mint(to_,amount);
            emit MintContract(to_,amount,address(tcontract));
        }
    }
    
    function burnEvent(address userAddr, uint256 amount) public {
        bytes32 pid = terc20_pid[msg.sender];
        CoinInfo storage cInfo = _terc20Info[pid];
        require(cInfo.ci_oldContractAddr != address(0),"contract not exit");
        
        emit BurnBalance(userAddr,amount,cInfo.ci_oldContractAddr);
    }
    
    
    function getTContractAddr(string memory name,string memory symbol,uint256 decimals,address oldContracAddr)
        public
        view
        returns(address tContractAddr)
    {
        bytes32 newContrHash = keccak256(abi.encodePacked(name,symbol,decimals,oldContracAddr)); 
        tContractAddr = address(_erc20_terc20[newContrHash]);
    }
    
    function changeFounder(address payable newFounder) public {
        require(msg.sender == founder, "");

        founder = newFounder;
    }
}

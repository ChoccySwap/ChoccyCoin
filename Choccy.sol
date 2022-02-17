/**
  
   ChoccyCoin

   Chocconomics:
   10M supply, no tax
   
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

interface IRouter01 { //Change with your preferred router (UNI, pancake, Joe...)

    function addLiquidityETH(//or AVAX or whatever. if you change this, go to line 86 and 127 too
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );
}

contract PresalableERC20 is ERC20 {    
    bool public transfersActive;
    address public presaleController;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 10 * (1e6) * (1e18)); //10M supply
        presaleController = msg.sender;
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal view override { 
        require(transfersActive || from==address(0) || to==address(0) || from==presaleController, "Token hasn't launched yet!");
    }

    function activateTransfers() external {
        require(msg.sender == presaleController);
        transfersActive = true;
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}

contract devVesting {
    ERC20 public immutable token;
    uint public immutable amountStart;
    uint public immutable duration;
    uint public immutable start;
    address public immutable dev; //could let you transfer ownership of the token, but I don't see that happen often and it would increase the surface area

    constructor(uint _duration, ERC20 _token, address _dev, uint _amountStart){
        duration = _duration;
        start = block.timestamp;
        token = _token;
        dev = _dev;
        amountStart = _amountStart;
    }

    function takeFunds(uint amount) external{
        require(msg.sender == dev);
        token.transfer(dev, amount);
        uint age = block.timestamp - start;
        require(( amountStart - token.balanceOf(address(this)) ) <= amountStart*( (age*age)/(duration*duration) ), "You've taken too much");
    }
}

contract Fundraiser {
    PresalableERC20 public immutable token;
    address public immutable owner;
    mapping (address => bool) public wl;
    uint public minWL;
    uint public maxWL;
    uint public wlFactor;
    uint public numWL;
    bool public inWL = false;
    bool public inPS = false;
    uint public minPS;
    uint public maxPS;
    uint public psFactor;
    IRouter01 private constant ROUTER = IRouter01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//use joe if you use AVAX, spooky for FTM...
    devVesting public immutable vester;

    constructor(string memory name_, string memory symbol_, uint perThouDirect, uint perThouVested, uint inaccurateMonths) {
        token = new PresalableERC20(name_, symbol_);
        owner = msg.sender;
        uint amountVesting = (token.balanceOf(address(this))*perThouVested)/1000;
        uint amountDirect = (token.balanceOf(address(this))*perThouDirect)/1000;
        vester = new devVesting(inaccurateMonths*(30 days), token, owner, amountVesting);
        token.transfer(address(vester), amountVesting);
        token.transfer(owner, amountDirect);
    }
    
    function startWhitelist(address[] calldata _wl, uint _min, uint_max, uint _wlFactor) external{
        require(msg.sender == owner);
        for (uint i = 0; i< _wl.length; i++){
            wl[_wl[i]] = true;
        }
        numWL = _wl.length;
        minWL = _min;
        maxWL = _max;
        inWL = true;
        wlFactor = _wlFactor;
    }
    
    function startPublicPresale(uint _min, uint _max, uint _psFactor) external{ 
        require(msg.sender == owner);
        inPS = true;
        psFactor = _psFactor;
        minPS = _min;
        maxPS = _max;
        psFactor = _psFactor;
    }
    
    function startPool(uint maxLaunchTokensPerETH) external{
        require(msg.sender == owner);
        inWL = false;
        inPS = false;
        token.activateTransfers();
        address t = address(this);
        token.approve(address(ROUTER), token.balanceOf(t));
        uint amountLiq = t.balance * maxLaunchTokensPerETH;
        amountLiq = amountLiq>token.balanceOf(t)? token.balanceOf(t):amountLiq;
        ROUTER.addLiquidityETH{value: t.balance}(address(token), amountLiq, amountLiq, t.balance, t, block.timestamp);
        token.burn(token.balanceOf(t));
    }
    
    receive() external payable {
        if (inWL && wl[msg.sender]) {
            require(msg.value >= minWL, "You need to send more than that! Check the minWL value!");
            require(msg.value <= maxWL, "You need to send less than that! Check the maxWL value!");
            wl[msg.sender] = false;
            numWL--;
            inWL = numWL>0;
            token.transfer(msg.sender, msg.value * wlFactor);
            return;
        } else if (inPS) {
            require(msg.value >= minPS, "You need to send more than that! Check the minPS value!");
            require(msg.value <= maxPS, "You need to send less than that! Check the maxPS value!");
            token.transfer(msg.sender, msg.value * psFactor);
            return;
        }
        revert("You're not in the whitelist or the token has already launched!");
    }
}

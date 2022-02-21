/**
  
   ChoccyCoin

   Chocconomics:
   100M supply, no tax
   
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract Choccy is ERC20 {
    address public devV;
    address public presaler;

    constructor(string memory name_, string memory symbol_, //("ChoccyCoin","CCY", 10*1e6*1e18, 40*1e6*1e18, 18*(30days), 6*(30 days))
                uint amountDev, uint amountLiq, uint devVestTime, uint psVestTime) ERC20(name_, symbol_) {
        devV = address(new devVesting(devVestTime, this, msg.sender, amountDev));
        presaler = address(new Presaler(this, amountLiq, psVestTime));
        _mint(presaler, 100 * (1e6) * (1e18)); //100M supply
        _transfer(presaler, devV, amountDev);
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

contract Presaler {
    ERC20 public immutable token;
    uint public immutable amountLiq;
    address public immutable dev;
    uint public immutable vestDuration;
    mapping (address => uint) bought;
    mapping (address => uint) sent;
    bool public launched;
    uint factor;
    uint start;
    IRouter01 public swap = IRouter01(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);//<=JOE

    constructor(ERC20 _token, uint _amountLiq, uint _vest){
        token = _token;
        amountLiq = _amountLiq;
        vestDuration = _vest;
        dev = tx.origin;
    }

    receive() external payable {
        if (!launched) {
            bought[msg.sender] += msg.value;
        } else {
            revert("The token has already launched!");
        }
    }

    function _calcRetrievable(address who) internal view returns (uint am){
        uint timePercent = 50 + 50*(block.timestamp - start) / vestDuration;
        timePercent = timePercent > 100? 100 : timePercent;
        uint amount = (bought[who] * timePercent) / 100;
        uint toSend = amount - sent[who];
        return toSend;
    }

    function status(address who) public view returns (uint b, uint r) {
        return (bought[who], _calcRetrievable(who));
    }

    function getFactor() public view returns (uint) {
        return factor;
    }

    function launch() external{
        require(msg.sender == dev);
        launched = true;
        factor = (token.balanceOf(address(this))-amountLiq) / address(this).balance ;
        start = block.timestamp;
        token.approve(address(swap), amountLiq);
        swap.addLiquidityETH{value: address(this).balance}(address(token), amountLiq, amountLiq, address(this).balance, address(this), block.timestamp);
    }

    function retrieveToken() external{
        require(launched, "Presale hasn't ended yet!");
        uint toSend = _calcRetrievable(msg.sender);
        sent[msg.sender] += toSend;
        token.transfer(msg.sender, toSend * factor);
    }
}


interface IRouter01 { //Change with your preferred router (UNI, pancake, Joe...)

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountAVAX,
            uint liquidity
        );
}

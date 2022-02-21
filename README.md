# ChoccyCoin
The governance token for ChoccySwap. We have 100M total supply.
This is the smart contract we're using, and it should be publicly available for others to use too.
(for CoinWithPresale.sol, look at README.old)
(if you want a treasury, look at the actual code we're using, ChoccyFinal.sol, but keep in mind the data is hardcoded there)

This code WILL NOT work if you just plug it and try to start. This is on purpose, please read thise file before trying to clone it.

Here's a quick explanation if you wanna make a coin with presale:

### To start the fundraising

put this code in Remix, and deploy "Choccy" (rename it if you want) with these arguments:
<ul>
  <li>your coin name and symbol</li>
  <li>max amount a wallet can buy through the phases of the sale</li>
  <li>amount that you wanna give to the dev</li>
  <li>amount to put in liquidity</li>
  <li>number of seconds to vest the dev fund over</li>
  <li>number of seconds to vest the buyers' funds over</li>
</ul>
example: Choccy("ChoccyCoin","CCY", 10*1e6*1e18, 40*1e6*1e18, 18*(30days), 6*(30 days)) creates a coin named "ChoccyCoin", symbol CCY, that gives 10M token to the founder, 40M token in liquidity (leaving 50M in presale); the dev fund is quadratically vested over 18 months, while people can get their funds back through a vesting process that gives them 50% at start, while the rest is linearly unlocked over 6 months.

### Public presale

If a user wants to buy some tokens, they just need to send ETH (the main currency on your chain, could be AVAX or FTM) to the Presale address. They'll get registered, but they won't get anything until you launch the tokens (so noone can start a pool before launch). They can buy in multiple times.

### Launch

use Presaler.launch with no arguments.

Noone can send ETH anymore to the contract.
The tokens now can be retrieved from the contract.

### To get your vested tokens

Choccy.devV.getFunds(amount) will give you the requested amount, if it doesn't exceed the max amount you can request at that point in time. 
example: Fundraiser.vester.getFunds(1e18) will give you 1 token, if it has 18 decimals

It doesn't automatically give you all it can as to encourage devs in taking only the necessary amount, leaving any surplus in the vester until required. If a dev wants to dump, he either has to constantly take any funds he can from the vester, or has to do a massive fund retrieval before dumping, which may attract other people's attention, which would hopefully alert the community.

### For people to get their tokens

Choccy.presaler.retrieveTokens() will give them as much as they can retrieve at that point in time.

### Why it won't work

You have to put the right contract address in it, and be sure to check that IRouter01 uses the correct function name (addLiquidityETH, or AVAX...)

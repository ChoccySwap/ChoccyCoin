# ChoccyCoin
The governance token for ChoccySwap.
This is the smart contract we're using, and it should be publicly available for others to use too.

Here's a quick explanation if you wanna make a coin with presale(s):

### To start the fundraising

put this code in Remix, and deploy "Fundraiser" with these arguments:
<ul>
  <li>your coin name and symbol</li>
  <li>amount ‰ that you wanna give to the dev</li>
  <li>amount ‰ to vest</li>
  <li>number of (inexact) months to vest over</li>
</ul>
example: Fundraiser("ChoccyCoin", "CCY", 0, 100, 18) creates a coin with 0% dev fund going directly to the dev, and 10% vesting over 18 months (actually, 18*30 days... with leap second inaccuracies)

### Whitelisted presale (optional)

use Fundraiser.startWhitelist with these arguments:
<ul>
  <li>the whitelisted addresses</li>
  <li>minimum buy for the whitelist</li>
  <li>maximum buy for the whitelist</li>
  <li>number of tokens to give for each ETH (or AVAX, or FTM) during whitelist</li>
</ul>
example: Fundraiser.startWhitelist(["address1", "address2"], 125*1e16, 1e30, 4000) will give 4000 tokens per ETH, only to whitelisted addresses (address1 and address2).
They can't buy less than 1.25 ETH or more than 1T ETH (too high, obviously) in this case.

if a user wants to buy some tokens, they just need to send ETH (or AVAX... you get it) to the fundraiser address. They'll get the right amount of tokens back, but they can't do transactions until you launch the tokens (so noone can start a pool before launch).


### Public presale (optional)

use Fundraiser.startPublicPresale with these arguments:
<ul>
  <li>minimum buy for the presale (can be different than whitelist)</li>
  <li>maximum buy for the presale (can be different than whitelist)</li>
  <li>number of tokens to give for each ETH (or AVAX, or FTM) during public presale (can be different than whitelist, and should be lower if you made a whitelist)</li>
</ul>
example: Fundraiser.startPublicPresale(0, 1e15, 3809) starts a public presale with no lower buy limit and 3809 tokens per ETH. Noone can buy more than 0.001 ETH.

if a user wants to buy some tokens, they just need to send ETH (or AVAX... you get it) to the fundraiser address. They'll get the right amount of tokens back, but they can't do transactions until you launch the tokens (so noone can start a pool before launch). If you had a whitelist it won't get stopped, so that if someone had a spot on the whitelist but didn't buy in time he can still get his tokens


### Launch

use Fundraiser.startPool with these arguments:
<ul>
  <li>max amount of tokens to get per each ETH. Any surplus supply gets burnt (should be lower than both wl and ps)</li>
</ul>
example: Fundraiser.startPool(3636) starts the uniswapv2 pool with an inverse price of 3636 tokens per ETH or lower.

Noone can send ETH anymore to the contract.
The token now becomes swappable.

### To get your vested tokens

Fundraiser.vester.getFunds(amount) will give you the requested amount, if it doesn't exceed the max amount you can request at that point in time. 
example: Fundraiser.vester.getFunds(1e18) will give you 1 token, if it has 18 decimals

It doesn't automatically give you all it can as to encourage devs in taking only the necessary amount, leaving any surplus in the vester until required. If a dev wants to dump, he either has to constantly take any funds he can from the vester, or has to do a massive fund retrieval before dumping, which may attract other people's attention, which would hopefully alert the community.

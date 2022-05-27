## Damn Vulnerable DeFi(solved)

## 1. Unstoppable
We deposit tokens directly using the transfer function to ensure that poolBalance < balanceBefore.
## 2. Naive-receiver
Since the fee is 1 ether, all we have to do is execute a flashloan for 0 ether 10 times to drain out the user's balance.
Another way to do it in a single transaction would be to deploy a contract that keeps executing a flashloan with the receiver's address for 0 ether until the user contract balance is 0.
## 3. Truster
We deploy a contract and encode an approve function call to withdraw the entire balance of the lender contract. We pass this encoded call as data along with a flashloan request, and once this is called, we withdraw the entire balance using transferFrom.
## 4. Side-entrance
We write and deploy a contract that executes a flashloan for all of the pool's balance, then write the execute() function that implements the interface function to deposit the borrowed flashloan. Once the flashloan is done executing, we withdraw the deposited amount from the pool, and send it to the user.
## 5. The rewarder
First wait for 5 days for the start of the new round. Deploy the attack contract. This contract executes a flashloan for all the DVT tokens held by the flashloan contract. The flashloan function calls the fallback function in our contract, where we deposit the tokens and withdraw with all the rewards and then return the flashloan amount. 
## 6. Selfie
Create and deploy a contract where we execute a flashloan for the DVT balance of the Pool. Using this balance, we take a snapshot and use it to acquire the majority votes in the governance contract. Now all we have to do is return the flashloan, queue the attack with a call to drainAllFunds with the attacker address, and wait for the required delay time(2 days), then execute the queued action.
## 7. Compromised
The data given turn out to be the private keys of the two oracles. We use this to manipulate the price to 0 before buying the NFT and manipulate it to be higher before selling to drain all the ETH.
## 8. Puppet
The goal is to manipulate the Uniswap price oracle such that the amount of tokens exceeds the amount of ETH locked in pool, thereby making the price of the pair very small. This allows us to steal all the tokens. We do this by sending our surplus DVT tokens to Uniswap, manipulating the price and swapping ETH for the maximum amount of tokens available.
## 9. Puppet V2
The price can be manipulated in the same way as the previous problem. All we need to do is swap our DVT tokens for ETH, wrap the ETH, approve and borrow all the tokens from the lending pool.
## 10. Free rider
While selling the NFT to the new purchaser, the marketplace contract sends the purchased amount back to the new owner since the owner is updated before the transaction happens. Hence all that is required is to get a flashloan, claim all the NFTs and repay the loan.
## 11. Backdoor
We exploit the GnossisSafe's proxy deployments by using a payload to delegateCall, essentially serving as a backdoor. Our goal is to get the proxy to approve all the DVT tokens for ourselves by using this backdoor.
## 12. Climber
We write and deploy an attacker contract that manipulates the vault timelock, grants us the proposer role, and lets us claim ownership. We then deploy another upgradeable contract for ClimberVault with a modified sweepFunds function, through which we can sweep all the funds.
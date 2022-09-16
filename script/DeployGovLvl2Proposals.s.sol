// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import { AaveEcosystemReserveV2 } from "src/contracts/AaveEcosystemReserveV2.sol";
import { Executor } from "src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "src/contracts/ProposalPayloadNewLongExecutor.sol";
import { ProposalPayloadAaveEcosystemReserveWithVoting } from "src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol";
import { AutonomousGovLvl2Proposal } from 'src/contracts/AutonomousGovLvl2Proposal.sol';

contract DeployGovLvl2Proposals is Script {
  bytes32 public constant LVL2_IPFS_HASH = bytes32(0); // TODO: add correct hash
  bytes32 public constant RESERVE_ECOSYSTEM_IPFS_HASH = bytes32(0); // TODO: add correct hash

  // executor lvl2 parameters
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

    // ------------- LONG EXECUTOR ------------- //
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

    ProposalPayloadNewLongExecutor lvl2Payload = new ProposalPayloadNewLongExecutor(
      address(longExecutor)
    );

    // ------------- ECOSYSTEM RESERVE ------------- //
    AaveEcosystemReserveV2 aaveEcosystemReserveV2Impl = new AaveEcosystemReserveV2();

    ProposalPayloadAaveEcosystemReserveWithVoting ecosystemPayload = new ProposalPayloadAaveEcosystemReserveWithVoting(
      address(aaveEcosystemReserveV2Impl)
    );

    // ------------- AUTONOMOUS PROPOSAL ------------- //
    AutonomousGovLvl2Proposal autonomousGovLvl2Proposal = new AutonomousGovLvl2Proposal(address(lvl2Payload), address(ecosystemPayload), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH);

    vm.stopBroadcast();
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "forge-std/Script.sol";
import { AaveEcosystemReserveV2 } from "src/contracts/AaveEcosystemReserveV2.sol";
import { Executor } from "src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "src/contracts/ProposalPayloadNewLongExecutor.sol";
import { ProposalPayloadAaveEcosystemReserveWithVoting } from "src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol";
import {AutonomousProposalsForGovAdjustments} from "src/contracts/AutonomousProposalsForGovAdjustments.sol";

contract DeployGovLvl2Proposals is Script {
  bytes32 public constant LVL2_IPFS_HASH = 0x4bd95ce6e9a0d76c0dd3154da423f01ee010ea9491bb5ddf5a151e6ef22b674c;
  bytes32 public constant RESERVE_ECOSYSTEM_IPFS_HASH = 0x9c4249b03cdf9c2721b8b69d82a51bac19f35f4adbd09f194cc7d0cc449141d2;

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

  uint256 public constant CREATION_TIMESTAMP = 1664892000; // Tuesday, October 4, 2022 2:00:00 PM

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
    AutonomousProposalsForGovAdjustments autonomousGovLvl2Proposal = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(ecosystemPayload), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH, CREATION_TIMESTAMP);

    vm.stopBroadcast();
  }
}
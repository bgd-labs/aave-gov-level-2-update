// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers, IAaveGov} from 'aave-helpers/GovHelpers.sol';
import { AaveEcosystemReserveV2 } from "src/contracts/AaveEcosystemReserveV2.sol";
import { Executor } from "src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "src/contracts/ProposalPayloadNewLongExecutor.sol";
import { ProposalPayloadAaveEcosystemReserveWithVoting } from "src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol";
import {AutonomousProposalsForGovAdjustments} from "src/contracts/AutonomousProposalsForGovAdjustments.sol";
import {IGovernancePowerDelegationToken} from './utils/IGovernancePowerDelegationToken.sol';

contract AutonomousProposalsForGovAdjustmentsTest is Test {
  bytes32 public constant LVL2_IPFS_HASH = keccak256('lvl2 ifps hash');
  bytes32 public constant RESERVE_ECOSYSTEM_IPFS_HASH = keccak256('ecosystem ifps hash');

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

  uint256 public beforeProposalCount;

  ProposalPayloadNewLongExecutor public lvl2Payload;
  ProposalPayloadAaveEcosystemReserveWithVoting public ecosystemPayload;
  AutonomousProposalsForGovAdjustments public autonomousGovLvl2Proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("ethereum"), 15370248);
    beforeProposalCount = GovHelpers.GOV.getProposalsCount();

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

    lvl2Payload = new ProposalPayloadNewLongExecutor(
      address(longExecutor)
    );

    // ------------- ECOSYSTEM RESERVE ------------- //
    AaveEcosystemReserveV2 aaveEcosystemReserveV2Impl = new AaveEcosystemReserveV2();

    ecosystemPayload = new ProposalPayloadAaveEcosystemReserveWithVoting(
      address(aaveEcosystemReserveV2Impl)
    );

    // ------------- AUTONOMOUS PROPOSAL ------------- //
    autonomousGovLvl2Proposal = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(ecosystemPayload), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH);
  }

  function testCreateProposalsWhenAllInfoCorrect() public {
    _createProposals();

    // test that first proposal is lvl2 and second is ecosystem
    uint256 proposalsCount = GovHelpers.GOV.getProposalsCount();
    assertEq(proposalsCount, beforeProposalCount + 2);

    IAaveGov.ProposalWithoutVotes memory lvl2Proposal = GovHelpers.getProposalById(proposalsCount - 2);
    assertEq(lvl2Proposal.targets[0], address(lvl2Payload));
    assertEq(lvl2Proposal.ipfsHash, LVL2_IPFS_HASH);
    assertEq(lvl2Proposal.executor, GovHelpers.LONG_EXECUTOR);
    assertEq(keccak256(abi.encode(lvl2Proposal.signatures[0])), keccak256(abi.encode('execute()')));
    assertEq(keccak256(lvl2Proposal.calldatas[0]), keccak256(''));


    IAaveGov.ProposalWithoutVotes memory ecosystemProposal = GovHelpers.getProposalById(proposalsCount - 1);
    assertEq(ecosystemProposal.targets[0], address(ecosystemPayload));
    assertEq(ecosystemProposal.ipfsHash, RESERVE_ECOSYSTEM_IPFS_HASH);
    assertEq(ecosystemProposal.executor, GovHelpers.SHORT_EXECUTOR);
    assertEq(keccak256(abi.encode(ecosystemProposal.signatures[0])), keccak256(abi.encode('execute(uint256)')));
    assertEq(keccak256(ecosystemProposal.calldatas[0]), keccak256(abi.encode(proposalsCount - 2)));
  }

  function testCreateProposalsWithWrongIpfsLvl2() public {}

  function testCreateProposalsWithWrongPayloadLvl2() public {}

  function testCreateProposalsWithWrongIpfsEcosystem() public {}

  function testCreateProposalsWithWrongPayloadEcosystem() public {}

  function testCreateProposalsWithoutPropositionPower() public {}

  function testVotingAndExecution() public {
    _createProposals();

    // test that first proposal is lvl2 and second is ecosystem
    uint256 proposalsCount = GovHelpers.GOV.getProposalsCount();

  }

  function _createProposals() internal {
    hoax(GovHelpers.AAVE_WHALE);
    IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(address(autonomousGovLvl2Proposal), IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER);

    vm.roll(block.number + 10);

    autonomousGovLvl2Proposal.createProposalsForGovAdjustments();
  }
}
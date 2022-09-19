// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import { IERC20 } from "./utils/IERC20.sol";
import {GovHelpers, IAaveGov} from 'aave-helpers/GovHelpers.sol';
import { AaveEcosystemReserveV2 } from "src/contracts/AaveEcosystemReserveV2.sol";
import { Executor } from "src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "src/contracts/ProposalPayloadNewLongExecutor.sol";
import { ProposalPayloadAaveEcosystemReserveWithVoting } from "src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol";
import {AutonomousProposalsForGovAdjustments} from "src/contracts/AutonomousProposalsForGovAdjustments.sol";
import {IGovernancePowerDelegationToken} from './utils/IGovernancePowerDelegationToken.sol';

contract AutonomousProposalsForGovAdjustmentsTest is Test {
  IERC20 constant AAVE_TOKEN =
    IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

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

    assertEq(autonomousGovLvl2Proposal.proposalsCreated(), true);
  }

  function testCreateProposalsTwice() public {
    _createProposals();

    vm.expectRevert(bytes('PROPOSALS_ALREADY_CREATED'));
    autonomousGovLvl2Proposal.createProposalsForGovAdjustments();
  }

  function testCreateProposalsWithWrongIpfsLvl2() public {
    AutonomousProposalsForGovAdjustments autonomous = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(ecosystemPayload), bytes32(0), RESERVE_ECOSYSTEM_IPFS_HASH);

    vm.expectRevert(bytes('IPFS_HASH_BYTES32_0'));
    autonomous.createProposalsForGovAdjustments();
  }

  function testCreateProposalsWithWrongPayloadLvl2() public {
    AutonomousProposalsForGovAdjustments autonomous = new AutonomousProposalsForGovAdjustments(address(0), address(ecosystemPayload), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH);

    vm.expectRevert(bytes('PAYLOAD_ADDRESS_0'));
    autonomous.createProposalsForGovAdjustments();
  }

  function testCreateProposalsWithWrongIpfsEcosystem() public {
    AutonomousProposalsForGovAdjustments autonomous = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(ecosystemPayload), LVL2_IPFS_HASH, bytes32(0));

    hoax(GovHelpers.AAVE_WHALE);
    IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(address(autonomous), IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER);

    vm.roll(block.number + 10);

    vm.expectRevert(bytes('IPFS_HASH_BYTES32_0'));
    autonomous.createProposalsForGovAdjustments();
  }

  function testCreateProposalsWithWrongPayloadEcosystem() public {
    AutonomousProposalsForGovAdjustments autonomous = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(0), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH);

    hoax(GovHelpers.AAVE_WHALE);
    IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(address(autonomous), IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER);

    vm.roll(block.number + 10);

    vm.expectRevert(bytes('PAYLOAD_ADDRESS_0'));
    autonomous.createProposalsForGovAdjustments();
  }

  function testCreateProposalsWithoutPropositionPower() public {
    AutonomousProposalsForGovAdjustments autonomous = new AutonomousProposalsForGovAdjustments(address(lvl2Payload), address(ecosystemPayload), LVL2_IPFS_HASH, RESERVE_ECOSYSTEM_IPFS_HASH);

    vm.expectRevert((bytes('PROPOSITION_CREATION_INVALID')));
    autonomous.createProposalsForGovAdjustments();
  }

  function testVotingAndExecution() public {
    _createProposals();

    // vote on ecosystem proposal
    uint256 proposalsCount = GovHelpers.GOV.getProposalsCount();

    GovHelpers.passVoteAndExecute(vm, proposalsCount - 1);

    IAaveGov.ProposalWithoutVotes memory lvl2Proposal = GovHelpers.getProposalById(proposalsCount - 2);
    uint256 votingPower = AAVE_TOKEN.balanceOf(address(ecosystemPayload.AAVE_ECOSYSTEM_RESERVE_PROXY()));
    assertEq(lvl2Proposal.forVotes, votingPower);
  }

  function _createProposals() internal {
    hoax(GovHelpers.AAVE_WHALE);
    IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(address(autonomousGovLvl2Proposal), IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER);

    vm.roll(block.number + 10);

    autonomousGovLvl2Proposal.createProposalsForGovAdjustments();
  }
}
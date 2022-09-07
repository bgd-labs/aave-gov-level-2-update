// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import 'forge-std/Test.sol';
import {Executor} from '../src/contracts/Executor.sol';

contract ExecutorTest is Test {
  address public constant ADMIN = address(1234);
  uint256 public constant DELAY = 604800;
  uint256 public constant GRACE_PERIOD = 432000;
  uint256 public constant MINIMUM_DELAY = 604800;
  uint256 public constant MAXIMUM_DELAY = 864000;
  uint256 public constant PROPOSITION_THRESHOLD = 200;
  uint256 public constant VOTING_DURATION = 64000;
  uint256 public constant VOTE_DIFFERENTIAL = 1500;
  uint256 public constant MINIMUM_QUORUM = 1200;

  Executor public executor;

  // events
  event VotingDurationUpdated(uint256 newVotingDuration);
  event VoteDifferentialUpdated(uint256 newVoteDifferential);
  event MinimumQuorumUpdated(uint256 newMinimumQuorum);
  event PropositionThresholdUpdated(uint256 newPropositionThreshold);
  event NewDelay(uint256 delay);
  event NewPendingAdmin(address newPendingAdmin);
  
  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("ethereum"), 15370248);

    executor = new Executor(
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
  }

  function testContstructor() public {
    assertEq(ADMIN, executor.getAdmin());
    assertEq(DELAY, executor.getDelay());
    assertEq(GRACE_PERIOD, executor.GRACE_PERIOD());
    assertEq(MINIMUM_DELAY, executor.MINIMUM_DELAY());
    assertEq(MAXIMUM_DELAY, executor.MAXIMUM_DELAY());
    assertEq(PROPOSITION_THRESHOLD, executor.PROPOSITION_THRESHOLD());
    assertEq(VOTING_DURATION, executor.VOTING_DURATION());
    assertEq(VOTE_DIFFERENTIAL, executor.VOTE_DIFFERENTIAL());
    assertEq(MINIMUM_QUORUM, executor.MINIMUM_QUORUM());
  }

  function testUpdateVotingDuration() public {
    
    uint256 newVotingDuration = 54000;

    vm.expectEmit(false, false, false, true);
    emit VotingDurationUpdated(newVotingDuration);

    hoax(address(executor));
    executor.updateVotingDuration(newVotingDuration);

    assertEq(newVotingDuration, executor.VOTING_DURATION());
  }

  function testUpdateVotingDurationWhenNotAdmin() public {
    uint256 newVotingDuration = 54000;

    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.updateVotingDuration(newVotingDuration);
  }

  function testUpdateVotingDurationWhen0() public {
    hoax(address(executor));
    uint256 newVotingDuration = 0;

    vm.expectRevert(bytes('VOTING_DURATION_CAN_NOT_BE_0'));
    executor.updateVotingDuration(newVotingDuration);
  }

  function testUpdateVoteDifferential() public {
    hoax(address(executor));
    uint256 newVoteDifferential = 2000;

    vm.expectEmit(false, false, false, true);
    emit VoteDifferentialUpdated(newVoteDifferential);

    executor.updateVoteDifferential(newVoteDifferential);
    assertEq(newVoteDifferential, executor.VOTE_DIFFERENTIAL());
  }

  function testUpdateVoteDifferentialWhenGreaterThan100() public {
    hoax(address(executor));
    uint256 newVoteDifferential = 20000;
    vm.expectRevert(bytes('VOTE_DIFFERENTIAL_CAN_NOT_BE_GREATER_THAN_100%'));
    executor.updateVoteDifferential(newVoteDifferential);
  }

  function testUpdateVoteDifferentialWhen0() public {
    hoax(address(executor));
    uint256 newVoteDifferential = 0;
    vm.expectRevert(bytes('VOTE_DIFFERENTIAL_CAN_NOT_BE_LESS_THAN_0'));
    executor.updateVoteDifferential(newVoteDifferential);
  }

  function testUpdateVoteDifferentialWhenNotAdmin() public {
    uint256 newVoteDifferential = 2000;
    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.updateVoteDifferential(newVoteDifferential);
  }

  function testUpdateMinimumQuorum() public {
    hoax(address(executor));
    uint256 newMinimumQuorum = 4000;

    vm.expectEmit(false, false, false, true);
    emit MinimumQuorumUpdated(newMinimumQuorum);

    executor.updateMinimumQuorum(newMinimumQuorum);
    assertEq(newMinimumQuorum, executor.MINIMUM_QUORUM());
  }

  function testUpdateMinimumQuorumWhenNotAdmin() public {
    uint256 newMinimumQuorum = 4000;
    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.updateMinimumQuorum(newMinimumQuorum);
  }

  function testUpdateMinimumQuorumWhenGreaterThan100() public {
    hoax(address(executor));
    uint256 newMinimumQuorum = 40000;
    vm.expectRevert(bytes('MINIMUM_QUORUM_CAN_NOT_BE_GREATER_THAN_100%'));
    executor.updateMinimumQuorum(newMinimumQuorum);
  }

  function testUpdateMinimumQuorumWhen0() public {
    hoax(address(executor));
    uint256 newMinimumQuorum = 0;
    vm.expectRevert(bytes('MINIMUM_QUORUM_CAN_NOT_BE_LESS_THAN_0'));
    executor.updateMinimumQuorum(newMinimumQuorum);
  }

  function testUpdatePropositionThreshold() public {
    hoax(address(executor));
    uint256 newMinimumPropositionThreshold = 300;

    vm.expectEmit(false, false, false, true);
    emit PropositionThresholdUpdated(newMinimumPropositionThreshold);

    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
    assertEq(newMinimumPropositionThreshold, executor.PROPOSITION_THRESHOLD());
  }

  function testUpdatePropositionThresholdToGreaterThan100() public {
    hoax(address(executor));
    uint256 newMinimumPropositionThreshold = 10001;

    vm.expectRevert(bytes('PROPOSITION_THRESHOLD_CAN_NOT_BE_GREATER_THAN_100%'));
    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
  }

  function testUpdatePropositionThresholdTo0() public {
    hoax(address(executor));
    uint256 newMinimumPropositionThreshold = 0;

    vm.expectRevert(bytes('PROPOSITION_THRESHOLD_CAN_NOT_BE_LESS_THAN_0'));
    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
  }

  function testUpdatePropositionThresholdWhenNotAdmin() public {
    uint256 newMinimumPropositionThreshold = 300;
    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
  }

  function testSetDelay() public {
    uint256 newDelay = 604842;
    hoax(address(executor));

    vm.expectEmit(false,false,false,true);
    emit NewDelay(newDelay);
    executor.setDelay(newDelay);

    assertEq(executor.getDelay(), newDelay);
  }

  function testSetDelayWhenNotExecutor() public {
    uint256 newDelay = 42;

    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.setDelay(newDelay);
  }

  function testSetPendingAdmin() public {
    address newAdmin = address(98123654);

    hoax(address(executor));

    vm.expectEmit(false,false,false,true);
    emit NewPendingAdmin(newAdmin);
    executor.setPendingAdmin(newAdmin);

    assertEq(executor.getPendingAdmin(), newAdmin);
  } 

  function testSetPendingAdminWhenNotExecutor() public {
    address newAdmin = address(98123654);

    vm.expectRevert(bytes('CALLER_NOT_EXECUTOR'));
    executor.setPendingAdmin(newAdmin);
  } 
}
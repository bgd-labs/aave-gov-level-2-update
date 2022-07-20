// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IGovernanceStrategy} from './interfaces/IGovernanceStrategy.sol';
import {IAaveGovernanceV2} from './interfaces/IAaveGovernanceV2.sol';
import {IExecutor} from './interfaces/IExecutor.sol';


/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author Aave
 **/
contract Executor is IExecutor {
  uint256 public immutable override GRACE_PERIOD;
  uint256 public immutable override MINIMUM_DELAY;
  uint256 public immutable override MAXIMUM_DELAY;

  address private _admin;
  address private _pendingAdmin;
  uint256 private _delay;

  mapping(bytes32 => bool) private _queuedTransactions;

  uint256 public override PROPOSITION_THRESHOLD;
  uint256 public override VOTING_DURATION;
  uint256 public override VOTE_DIFFERENTIAL;
  uint256 public override MINIMUM_QUORUM;
  uint256 public constant override ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision


    /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal
   * @param gracePeriod time after `delay` while a proposal can be executed
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threhold of `delay`, in seconds
   * @param propositionThreshold minimum percentage of supply needed to submit a proposal
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param voteDuration duration in blocks of the voting period
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )  
  {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _admin = admin;

    GRACE_PERIOD = gracePeriod;
    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewAdmin(admin);

    _updateVotingDuration(voteDuration);
    _updateVoteDifferential(voteDifferential);
    _updateMinimumQuorum(minimumQuorum);
    _updatePropositionThreshold(propositionThreshold);
  }

  /**
  * -------------------------------------------------------------
  * --------------- IExecutorWithTimelock -----------------------
  * @dev Contract that can queue, execute, cancel transactions voted by Governance
  * Queued transactions can be executed after a delay and until
  * Grace period is not over.
  * -------------------------------------------------------------
  */

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  /// @inheritdoc IExecutor
  function setDelay(uint256 delay) external override onlyExecutor {
    _validateDelay(delay);
    _delay = delay;

    emit NewDelay(delay);
  }

  /// @inheritdoc IExecutor
  function acceptAdmin() external override onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /// @inheritdoc IExecutor
  function setPendingAdmin(address newPendingAdmin) external override onlyExecutor {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /// @inheritdoc IExecutor
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external override onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp + _delay, 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external override onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable override onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    require(block.timestamp <= executionTime + GRACE_PERIOD, 'GRACE_PERIOD_FINISHED');

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, 'NOT_ENOUGH_MSG_VALUE');
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /// @inheritdoc IExecutor
  function getAdmin() external view override returns (address) {
    return _admin;
  }

  /// @inheritdoc IExecutor
  function getPendingAdmin() external view override returns (address) {
    return _pendingAdmin;
  }

  /// @inheritdoc IExecutor
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /// @inheritdoc IExecutor
  function isActionQueued(bytes32 actionHash) external view override returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /// @inheritdoc IExecutor
  function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime + GRACE_PERIOD);
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  // TODO: don't get why this is needed
  receive() external payable {}




  /**
  * --------------------------------------------------------
  * ---------- Proposal Validation -------------------------
  * @dev Validates/Invalidations propositions state modifications.
  * Proposition Power functions: Validates proposition creations/ cancellation
  * Voting Power functions: Validates success of propositions.
  * --------------------------------------------------------
  */

  /// @inheritdoc IExecutor
  function updateVotingDuration(uint256 votingDuration) external override onlyExecutor {
    _updateVotingDuration(votingDuration);
  }
  
  /// @inheritdoc IExecutor
  function updateVoteDifferential(uint256 voteDifferential) external override onlyExecutor {
    _updateVoteDifferential(voteDifferential);
  }

  /// @inheritdoc IExecutor
  function updateMinimumQuorum(uint256 minimumQuorum) external override onlyExecutor {
    _updateMinimumQuorum(minimumQuorum);
  }

  /// @inheritdoc IExecutor
  function updatePropositionThreshold(uint256 propositionThreshold) external override onlyExecutor {
    _updatePropositionThreshold(propositionThreshold);
  }

  /// @inheritdoc IExecutor
  function validateCreatorOfProposal(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view override returns (bool) {
    return isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function validateProposalCancellation(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view override returns (bool) {
    return !isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function isPropositionPowerEnough(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) public view override returns (bool) {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy.getPropositionPowerAt(user, blockNumber) >=
      getMinimumPropositionPowerNeeded(governance, blockNumber);
  }

  /// @inheritdoc IExecutor
  function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy
        .getTotalPropositionSupplyAt(blockNumber)
        * PROPOSITION_THRESHOLD
        / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /// @inheritdoc IExecutor
  function getMinimumVotingPowerNeeded(uint256 votingSupply)
    public
    view
    override
    returns (uint256)
  {
    return votingSupply * MINIMUM_QUORUM / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    override
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
  }

  /// @inheritdoc IExecutor
  function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    override
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return (proposal.forVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) >
      ((proposal.againstVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) +
        VOTE_DIFFERENTIAL);
  }

  /// updates voting duration
  function _updateVotingDuration(uint256 votingDuration) internal {
    VOTING_DURATION = votingDuration;
    emit VotingDurationUpdated(VOTING_DURATION);
  }

  /// updates vote differential
  function _updateVoteDifferential(uint256 voteDifferential) internal {
    VOTE_DIFFERENTIAL = voteDifferential;
    emit VoteDifferentialUpdated(VOTE_DIFFERENTIAL);
  }

  /// updates minimum quorum
  function _updateMinimumQuorum(uint256 minimumQuorum) internal {
    MINIMUM_QUORUM = minimumQuorum;
    emit MinimumQuorumUpdated(MINIMUM_QUORUM);
  }

  /// updates proposition threshold
  function _updatePropositionThreshold(uint256 propositionThreshold) internal {
    PROPOSITION_THRESHOLD = propositionThreshold;
    emit PropositionThresholdUpdated(PROPOSITION_THRESHOLD);
  }

  modifier onlyExecutor {
    require(msg.sender == address(this), 'CALLER_NOT_EXECUTOR');
    _;
  }
}
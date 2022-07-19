```diff --git a/./etherscan/Executor/Executor.sol b/./src/contracts/LongExecutor.sol
index 01c891e..8cd6e2d 100644
--- a/./etherscan/Executor/Executor.sol
+++ b/./src/contracts/LongExecutor.sol
@@ -923,6 +923,39 @@ contract ExecutorWithTimelock is IExecutorWithTimelock {
 }
 
 interface IProposalValidator {
+  // event triggered when voting duration gets updated by the admin
+  event VotingDurationUpdated(uint256 newVotingDuration);
+  // event triggered when vote differential gets updated by the admin
+  event VoteDifferentialUpdated(uint256 newVoteDifferential);
+  // event triggered when minimum quorum gets updated by the admin
+  event MinimumQuorumUpdated(uint256 newMinimumQuorum);
+  // event triggered when proposition threshold gets updated by the admin
+  event PropositionThresholdUpdated(uint256 newPropositionThreshold);
+  
+  /**
+  * @dev method tu update the voting duration of the proposal. Only callable by admin.
+  * @param votingDuration duration of the vote
+  */
+  function updateVotingDuration(uint256 votingDuration) external;
+
+  /**
+  * @dev method to update the vote differential needed to pass the proposal. Only callable by admin.
+  * @param voteDifferential differential needed on the votes to pass the proposal
+  */
+  function updateVoteDifferential(uint256 voteDifferential) external;
+
+  /**
+  * @dev method to update the minimum quorum needed to pass the proposal. Only callable by admin.
+  * @param minimumQuorum quorum needed to pass the proposal 
+  */
+  function updateMinimumQuorum(uint256 minimumQuorum) external;
+
+  /**
+    * @dev method to update the propositionThreshold. Only callable by admin.
+    * @param propositionThreshold new proposition threshold
+    **/
+  function updatePropositionThreshold(uint256 propositionThreshold) external;
+
   /**
    * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
    * @param governance Governance Contract
@@ -1058,10 +1091,10 @@ interface IProposalValidator {
 contract ProposalValidator is IProposalValidator {
   using SafeMath for uint256;
 
-  uint256 public immutable override PROPOSITION_THRESHOLD;
-  uint256 public immutable override VOTING_DURATION;
-  uint256 public immutable override VOTE_DIFFERENTIAL;
-  uint256 public immutable override MINIMUM_QUORUM;
+  uint256 public override PROPOSITION_THRESHOLD;
+  uint256 public override VOTING_DURATION;
+  uint256 public override VOTE_DIFFERENTIAL;
+  uint256 public override MINIMUM_QUORUM;
   uint256 public constant override ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision
 
   /**
@@ -1081,10 +1114,30 @@ contract ProposalValidator is IProposalValidator {
     uint256 voteDifferential,
     uint256 minimumQuorum
   ) {
-    PROPOSITION_THRESHOLD = propositionThreshold;
-    VOTING_DURATION = votingDuration;
-    VOTE_DIFFERENTIAL = voteDifferential;
-    MINIMUM_QUORUM = minimumQuorum;
+    _updateVotingDuration(votingDuration);
+    _updateVoteDifferential(voteDifferential);
+    _updateMinimumQuorum(minimumQuorum);
+    _updatePropositionThreshold(propositionThreshold);
+  }
+
+  /// @inheritdoc IProposalValidator
+  function updateVotingDuration(uint256 votingDuration) external override onlyExecutor {
+    _updateVotingDuration(votingDuration);
+  }
+  
+  /// @inheritdoc IProposalValidator
+  function updateVoteDifferential(uint256 voteDifferential) external override onlyExecutor {
+    _updateVoteDifferential(voteDifferential);
+  }
+
+  /// @inheritdoc IProposalValidator
+  function updateMinimumQuorum(uint256 minimumQuorum) external override onlyExecutor {
+    _updateMinimumQuorum(minimumQuorum);
+  }
+
+  /// @inheritdoc IProposalValidator
+  function updatePropositionThreshold(uint256 propositionThreshold) external override onlyExecutor {
+    _updatePropositionThreshold(propositionThreshold);
   }
 
   /**
@@ -1234,6 +1287,35 @@ contract ProposalValidator is IProposalValidator {
         VOTE_DIFFERENTIAL
       ));
   }
+
+  /// updates voting duration
+  function _updateVotingDuration(uint256 votingDuration) internal {
+    VOTING_DURATION = votingDuration;
+    emit VotingDurationUpdated(VOTING_DURATION);
+  }
+
+  /// updates vote differential
+  function _updateVoteDifferential(uint256 voteDifferential) internal {
+    VOTE_DIFFERENTIAL = voteDifferential;
+    emit VoteDifferentialUpdated(VOTE_DIFFERENTIAL);
+  }
+
+  /// updates minimum quorum
+  function _updateMinimumQuorum(uint256 minimumQuorum) internal {
+    MINIMUM_QUORUM = minimumQuorum;
+    emit MinimumQuorumUpdated(MINIMUM_QUORUM);
+  }
+
+  /// updates proposition threshold
+  function _updatePropositionThreshold(uint256 propositionThreshold) internal {
+    PROPOSITION_THRESHOLD = propositionThreshold;
+    emit PropositionThresholdUpdated(PROPOSITION_THRESHOLD);
+  }
+
+  modifier onlyExecutor {
+    require(msg.sender == address(this), 'CALLER_NOT_EXECUTOR');
+    _;
+  }
 }
 
 /**

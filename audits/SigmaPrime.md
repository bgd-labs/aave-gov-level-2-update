# Aave Governance Long Executor Migration Review

## INFORMATIONAL: `isProposalOverGracePeriod()` Will Return `true` If The Proposal Does Not Exist Or Is Not Yet Queued

`Executor.isProposalOverGracePeriod()` will return `true` if there is no proposal in the governance contract.

The following excerpt is taken from `Executor.sol` lines #249-257.

```solidity
function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime + GRACE_PERIOD);
  }
```

Main cause is in `AaveGovernanceV2.getProposalById()` which does not revert if proposal ID does not exist.
The return value will be a proposal initiated to all zeros.
Hence, `proposal.executionTime` will be zero and `block.timestamp > proposal.executionTime + GRACE_PERIOD` will always be `true`.

Similarly, if the proposal is not yet queued then `proposal.executionTime` will be zero causing the issue.

The impact is low significance as it is only called in `AaveGovernanceV2` by the function `getProposalState()` which already performs the desired check.
Hence, it is only external users manually calling `isProposalOverGracePeriod()` who will be impacted.

**Recommendations**

The optimal mitigation would be to have `AaveGovernanceV2` to revert if `getProposalById()` is called with a proposal ID greater than or equal to `_proposalsCount` and return `false` if `proposal.executionTime = 0`.

This would require updating the `AaveGovernanceV2` contract which does not seem like a worthwhile trade-off given the low impact of this issue.


## INFORMATIONAL: Insufficient Bounds Checks On `_updatePropositionThreshold()`, `_updateMinimumQuorum()`, `_updateVoteDifferential()`, `_updateVotingDuration()`

The functions `_updatePropositionThreshold()`, `_updateMinimumQuorum()`, `_updateVoteDifferential()` are setters for percentage values.
The percentages should be at least less than 10,000 (100%).
Setting values to higher than 100% could accidentally brick the contract since no votes could pass.
The risk is informational as changing these values requires a governance vote which should be checked by voters anyway.

`_updateVotingDuration()` should never allow a zero value as input otherwise the voting is bricked.
If the duration is zero then `startBlock = endBlock` and there is no time to vote.

Rated as informational as these value changes must be voted in by the governance who hopefully review the proposals before they vote.

**Recommendations**

Add upper bounds checks to the input value to ensure they are below some reasonable value.
- `_updatePropositionThreshold()`
- `_updateMinimumQuorum()`
- `_updateVoteDifferential()`

Additionally, ensure `_updateVotingDuration()` is non-zero.


## Miscellaneous

### Clarify in natspec whether durations and delays are in blocks vs timestamp.

One example in `Executor.sol` is that `delay` is a timestamp whereas `VOTING_DURATION` in blocks.

**Recommendations**

When both are block height and timestamp are used it is desirable append a descriptor to the variable name.

For example use `delayTime` or `VOTING_DURATION_BLOCKS`.

Note that due to compatibility with `AaveGovernanceV2` and `IExecutor` it may be undesirable to change variable names.

An alternative mitigation is to clearly document the units in the natspec.

### Identical proposals queued in the same block will overwrite each other in the executor.

The function `queueTransaction()` (`cancelTransaction()` and `executeTransaction()`) should do not hash `proposalId` into the action hash.

As a result if two identical proposal are queued in the same block (or otherwise with the same `executionTime`) then they will overlap in the `_queuedTransactions` mapping.

This would require two proposals to pass with the exact same fields and so has negligible likelihood. Furthermore, the impact is low as only one of these proposals may be executed or cancelled and then both will be removed from the queue.
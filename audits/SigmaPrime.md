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

The optimal mitigation would be to have `AaveGovernanceV2.getProposalById()` revert if it is called with a proposal ID greater than or equal to `_proposalsCount` and return `false` if `proposal.executionTime = 0`.

This would require updating the `AaveGovernanceV2` contract which does not seem like a worthwhile trade-off given the low impact of this issue.

**BGD answer**

This point will not be addressed, as it is out of bounds for this proposal.

## INFORMATIONAL: Insufficient Bounds Checks On `_updatePropositionThreshold()`, `_updateMinimumQuorum()`, `_updateVoteDifferential()`, `_updateVotingDuration()`

The functions `_updatePropositionThreshold()`, `_updateMinimumQuorum()`, `_updateVoteDifferential()` are setters for percentage values.
The percentages should be strictly less than 10,000 (100%).
Setting values to higher than 100% could brick the contract since proposals would be unable to pass.
The risk is informational as changing these values requires a governance proposal to pass, which should be checked by voters.

`_updateVotingDuration()` should never allow the duration to be set to zero, otherwise the voting is bricked.
If the duration is zero then `startBlock = endBlock` and there is no time to vote, the state will progress from pending to failed.

This issue is rated as informational as these value changes must be voted in by the governance who hopefully review the proposals before they vote.

**Recommendations**

Add upper bounds checks to the input values to ensure they are below some reasonable value, e.g. 100%.
- `_updatePropositionThreshold()`
- `_updateMinimumQuorum()`
- `_updateVoteDifferential()`

Additionally, ensure `_updateVotingDuration()` had a non-zero duration parameter.

**BGD answer**

Bound checks will be added to 100% (10000) on 
- `_updatePropositionThreshold()`
- `_updateMinimumQuorum()`
- `_updateVoteDifferential()`

and a check will also be added to ensure `_updateVotingDuration()` is non-zero.

## Miscellaneous

### Clarify in natspec whether durations and delays are in blocks vs timestamp.

One example in `Executor.sol` is that `delay` is a timestamp whereas `VOTING_DURATION` in blocks.

**Recommendations**

When both are block height and timestamp are used it is desirable to append a descriptor to the variable name.

For example use `delayTime` or `VOTING_DURATION_BLOCKS`.

Note that due to compatibility with `AaveGovernanceV2` and `IExecutor` it may be undesirable to change variable names.

An alternative mitigation is to clearly document the units in the natspec.

**BGD answer**

Natspec will be updated to clearly indicate if variable indicates time in seconds or indicates number of blocks.

### Identical proposals queued in the same block will overwrite each other in the executor.

The function `queueTransaction()` (`cancelTransaction()` and `executeTransaction()`) do not hash `proposalId` into the action hash.

As a result if two identical proposals are queued in the same block (or otherwise with the same `executionTime`) then they will overlap in the `_queuedTransactions` mapping.

This would require two proposals to pass with the exact same fields and so has negligible likelihood. Furthermore, the impact is low as only one of these proposals may be executed or cancelled and then both will be removed from the queue.

**BGD answer**

This point will not be addressed, as for the cases where a proposal needs to do two actions with the same parameters (which would be the case to trigger this exception), the actions should be added to the same payload
which would then not trigger this point.
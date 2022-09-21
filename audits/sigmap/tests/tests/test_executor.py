
# Tests `Executor` constructor
def test_executor_constructor(alice, bob, chain, constants, aave_governance_v2, Executor):
    admin = bob
    delay = 1234
    grace_period = 4321
    minimum_delay = 10
    maximum_delay = 10_000
    proposition_threshold = 10
    vote_duration = 99
    vote_differential = 100
    minimum_quorum = 50

    executor = alice.deploy(
        Executor,
        admin,
        delay,
        grace_period,
        minimum_delay,
        maximum_delay,
        proposition_threshold,
        vote_duration,
        vote_differential,
        minimum_quorum,
    )

    # Verify constructed state and getters
    assert executor.GRACE_PERIOD() == grace_period
    assert executor.MINIMUM_DELAY() == minimum_delay
    assert executor.MAXIMUM_DELAY() == maximum_delay
    assert executor.ONE_HUNDRED_WITH_PRECISION() == 10_000
    assert executor.PROPOSITION_THRESHOLD() == proposition_threshold
    assert executor.VOTING_DURATION() == vote_duration
    assert executor.VOTE_DIFFERENTIAL() == vote_differential
    assert executor.MINIMUM_QUORUM() == minimum_quorum

    assert executor.getAdmin() == admin
    assert executor.getPendingAdmin() == constants.ZERO_ADDRESS
    assert executor.getDelay() == delay

    assert executor.isActionQueued(bytes(32)) == False
    assert executor.isProposalOverGracePeriod(aave_governance_v2, 10_000) == True

    assert executor.validateCreatorOfProposal(aave_governance_v2, alice, 10_000) == False
    assert executor.validateProposalCancellation(aave_governance_v2, alice, 10_000) == True

    assert executor.isPropositionPowerEnough(aave_governance_v2, alice, chain.height) == False
    assert executor.getMinimumVotingPowerNeeded(44_000) == 44_000 * minimum_quorum // 10_000

    assert executor.tx.events['NewDelay']['delay'] == delay
    assert executor.tx.events['NewAdmin']['newAdmin'] == admin

    assert executor.tx.events['VotingDurationUpdated']['newVotingDuration'] == vote_duration
    assert executor.tx.events['VoteDifferentialUpdated']['newVoteDifferential'] == vote_differential
    assert executor.tx.events['MinimumQuorumUpdated']['newMinimumQuorum'] == minimum_quorum
    assert executor.tx.events['PropositionThresholdUpdated']['newPropositionThreshold'] == proposition_threshold


# Tests `Executor` function signatures match the old function signatures
def test_function_signatures(alice, long_executor, Executor):
    new_executor = alice.deploy(Executor, alice, 1, 1, 0, 10, 1, 1, 1, 1)

    # Validate each function in used by `AaveGovernanceV2` remains unchanged
    assert new_executor.getDelay.signature == long_executor.getDelay.signature
    
    assert new_executor.queueTransaction.signature == long_executor.queueTransaction.signature
    assert new_executor.executeTransaction.signature == long_executor.executeTransaction.signature
    assert new_executor.cancelTransaction.signature == long_executor.cancelTransaction.signature
    
    assert new_executor.isActionQueued.signature == long_executor.isActionQueued.signature
    assert new_executor.isProposalOverGracePeriod.signature == long_executor.isProposalOverGracePeriod.signature
    assert new_executor.isProposalPassed.signature == long_executor.isProposalPassed.signature

    assert new_executor.validateCreatorOfProposal.signature == long_executor.validateCreatorOfProposal.signature
    assert new_executor.validateProposalCancellation.signature == long_executor.validateProposalCancellation.signature

    assert new_executor.PROPOSITION_THRESHOLD.signature == long_executor.PROPOSITION_THRESHOLD.signature
    assert new_executor.VOTING_DURATION.signature == long_executor.VOTING_DURATION.signature
    assert new_executor.VOTE_DIFFERENTIAL.signature == long_executor.VOTE_DIFFERENTIAL.signature
    assert new_executor.MINIMUM_QUORUM.signature == long_executor.MINIMUM_QUORUM.signature

    assert new_executor.GRACE_PERIOD.signature == long_executor.GRACE_PERIOD.signature
    assert new_executor.MINIMUM_DELAY.signature == long_executor.MINIMUM_DELAY.signature
    assert new_executor.MAXIMUM_DELAY.signature == long_executor.MAXIMUM_DELAY.signature
    assert new_executor.ONE_HUNDRED_WITH_PRECISION.signature == long_executor.ONE_HUNDRED_WITH_PRECISION.signature


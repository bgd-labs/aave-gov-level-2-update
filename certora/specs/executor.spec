
methods{
    /* =================================
    ============= Executor =============
    ==================================== */
    isPropositionPowerEnough(address ,address ,uint256) returns (bool) envfree
    getMinimumPropositionPowerNeeded(address, uint256) returns (uint256) envfree
    isProposalOverGracePeriod(address, uint256) returns (bool)
    isProposalPassed(address, uint256) returns (bool) envfree
    isQuorumValid(address, uint256) returns (bool) envfree
    isVoteDifferentialValid(address, uint256) returns (bool) envfree
    getMinimumVotingPowerNeeded(uint256) returns (uint256) envfree
    PROPOSITION_THRESHOLD() returns (uint256) envfree
    VOTING_DURATION() returns (uint256) envfree
    VOTE_DIFFERENTIAL() returns (uint256) envfree
    MINIMUM_QUORUM() returns (uint256) envfree
    ONE_HUNDRED_WITH_PRECISION() returns (uint256) envfree
    GRACE_PERIOD() returns (uint256) envfree
    MINIMUM_DELAY() returns (uint256) envfree
    MAXIMUM_DELAY() returns (uint256) envfree
    getAdmin() returns (address) envfree
    getPendingAdmin() returns (address) envfree
    getDelay() returns (uint256) envfree
    isActionQueued(bytes32) returns (bool) envfree
    /* =================================
    ============= Aave Governance ======
    ==================================== */

    getProposalById(uint256) => NONDET
    getGovernanceStrategy() => NONDET
}

definition noExecuteTransaction(method f) returns bool = 
    f.selector != executeTransaction(address,uint256,string,bytes,uint256,bool).selector;


// The execution delay is always bounded by the minimum and maximum values.
invariant properDelay()
    MINIMUM_DELAY() <= getDelay() && getDelay() <= MAXIMUM_DELAY()
    filtered{f-> noExecuteTransaction(f)}

// The grace period is always larger than zero.
// Grace period is immutable. Only changes in constructor.
// Issue: if someone sets grace period too low, this makes the executor stuck forever.
invariant nonZeroGracePeriod()
    GRACE_PERIOD() > 0
    filtered{f-> noExecuteTransaction(f)}

// The voting duration is always larger than zero.
invariant nonZeroVotingDuration()
    VOTING_DURATION() > 0
    filtered{f-> noExecuteTransaction(f)}

// The minimum quorum is always larger than zero.
invariant nonZeroMinimumQuorum()
    MINIMUM_QUORUM() > 0
    filtered{f-> noExecuteTransaction(f)}

// The proposition threshold is always larger than zero.
invariant nonZeroPropositionThreshold()
    PROPOSITION_THRESHOLD() > 0
    filtered{f-> noExecuteTransaction(f)}

// The proposition threshold is always smaller than 100%.
invariant differentialLessThan100()
    VOTE_DIFFERENTIAL() < ONE_HUNDRED_WITH_PRECISION()
    filtered{f-> noExecuteTransaction(f)}

// The voting differential is always smaller than 100%.
invariant thresholdLessThan100()
    PROPOSITION_THRESHOLD() < ONE_HUNDRED_WITH_PRECISION()
    filtered{f-> noExecuteTransaction(f)}

// Only the admin (or pending admin) can change the admin.
rule onlyAdminChangesAdmin(method f)
filtered{f -> ! f.isView}
{
    env e;
    calldataarg args;

    address _admin = getAdmin();
    address _pendingAdmin = getPendingAdmin();
    f(e, args);
    address admin_ = getAdmin();
    assert f.selector == acceptAdmin().selector => (admin_ == _pendingAdmin && e.msg.sender == _pendingAdmin);
    assert f.selector != acceptAdmin().selector => (_admin != admin_ => e.msg.sender == _admin);
}

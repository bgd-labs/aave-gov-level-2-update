// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExecutor} from '../../src/contracts/interfaces/IExecutor.sol';

contract LongExecutorNewDelayProposal {
    IExecutor public immutable LONG_EXECUTOR;
    uint256 public immutable NEW_DELAY;
    uint256 public immutable NEW_VOTING_DURATION;
    uint256 public immutable NEW_DIFFERENTIAL;
    uint256 public immutable NEW_QUORUM;
    uint256 public immutable NEW_PROPOSITION_THRESHOLD;
    address public immutable NEW_ADMIN;

    constructor(
        address longExecutor,
        uint256 newDelay,
        address newAdmin,
        uint256 newVotingDuration,
        uint256 newDifferential,
        uint256 newQuorum,
        uint256 newPropositionThreshold
    ) {
        LONG_EXECUTOR = IExecutor(longExecutor);
        NEW_DELAY = newDelay;
        NEW_ADMIN = newAdmin;
        NEW_VOTING_DURATION = newVotingDuration;
        NEW_DIFFERENTIAL = newDifferential;
        NEW_QUORUM = newQuorum;
        NEW_PROPOSITION_THRESHOLD = newPropositionThreshold;
    }

    function execute() external {
        LONG_EXECUTOR.setDelay(NEW_DELAY); 
        LONG_EXECUTOR.setPendingAdmin(NEW_ADMIN); 
        LONG_EXECUTOR.updateVotingDuration(NEW_VOTING_DURATION); 
        LONG_EXECUTOR.updateVoteDifferential(NEW_DIFFERENTIAL); 
        LONG_EXECUTOR.updateMinimumQuorum(NEW_QUORUM); 
        LONG_EXECUTOR.updatePropositionThreshold(NEW_PROPOSITION_THRESHOLD); 
    }
}

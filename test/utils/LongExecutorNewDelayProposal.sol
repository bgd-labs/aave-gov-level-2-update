// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExecutor} from '../../src/contracts/interfaces/IExecutor.sol';

contract LongExecutorNewDelayProposal {
    IExecutor public immutable LONG_EXECUTOR;
    uint256 public immutable NEW_DELAY;

    constructor(address longExecutor, uint256 newDelay) {
        LONG_EXECUTOR = IExecutor(longExecutor);
        NEW_DELAY = newDelay;
    }

    function execute() external {
        LONG_EXECUTOR.setDelay(NEW_DELAY); 
    }
}

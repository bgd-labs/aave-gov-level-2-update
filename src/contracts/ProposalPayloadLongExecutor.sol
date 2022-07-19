// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { IAaveGovernanceV2 } from "./interfaces/IAaveGovernanceV2.sol";
import { IOwnable } from "./interfaces/IOwnable.sol";

contract ProposalPayloadLongExecutor {
    IAaveGovernanceV2 constant aaveGovernanceV2 = IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);
    uint256 public constant VOTING_DELAY = 86400; // 1 day

    address public immutable LONG_EXECUTOR;

    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant ABPT = 0x41A08648C3766F9F9d85598fF102a08f4ef84F84;
    address public constant stkAAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant stkABPT =
        0xa1116930326D21fB917d5A27F1E9943A9595fb47;

    // contracts
    IInitializableAdminUpgradeabilityProxy constant aaveProxy =
        IInitializableAdminUpgradeabilityProxy(AAVE);
    IInitializableAdminUpgradeabilityProxy constant abptProxy =
        IInitializableAdminUpgradeabilityProxy(ABPT);
    IInitializableAdminUpgradeabilityProxy constant stkAaveProxy =
        IInitializableAdminUpgradeabilityProxy(stkAAVE);
    IInitializableAdminUpgradeabilityProxy constant stkAbptProxy =
        IInitializableAdminUpgradeabilityProxy(stkABPT);

    constructor(address longExecutor) {
        LONG_EXECUTOR = longExecutor;
    }

    function execute() external {
        // Governance updates
        aaveGovernanceV2.setVotingDelay(VOTING_DELAY);

        address[] memory executorsToAuthorize = new address[](1);
        executorsToAuthorize[0] = LONG_EXECUTOR;
        aaveGovernanceV2.authorizeExecutors(executorsToAuthorize);

        // we don't call unauthorize executors just in case something goes wrong
        
        IOwnable(address(aaveGovernanceV2)).transferOwnership(LONG_EXECUTOR);

        // update damins
        aaveProxy.changeAdmin(LONG_EXECUTOR);
        abptProxy.changeAdmin(LONG_EXECUTOR);
        stkAaveProxy.changeAdmin(LONG_EXECUTOR);
        stkAbptProxy.changeAdmin(LONG_EXECUTOR);
    }
}

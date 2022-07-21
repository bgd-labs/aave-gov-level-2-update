// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { IAaveGovernanceV2 } from "./interfaces/IAaveGovernanceV2.sol";
import { IOwnable } from "./interfaces/IOwnable.sol";

contract ProposalPayloadLongExecutor {
    IAaveGovernanceV2 constant AAVE_GOVERNANCE_V2 = IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);
    uint256 public constant VOTING_DELAY = 6443; // blocks in a day
    address public constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address public immutable LONG_EXECUTOR;

    // contracts
    IInitializableAdminUpgradeabilityProxy constant AAVE_PROXY =
        IInitializableAdminUpgradeabilityProxy(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IInitializableAdminUpgradeabilityProxy constant ABPT_PROXY =
        IInitializableAdminUpgradeabilityProxy(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);
    IInitializableAdminUpgradeabilityProxy constant STK_AAVE_PROXY =
        IInitializableAdminUpgradeabilityProxy(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    IInitializableAdminUpgradeabilityProxy constant STK_ABPT_PROXY =
        IInitializableAdminUpgradeabilityProxy(0xa1116930326D21fB917d5A27F1E9943A9595fb47);

    constructor(address longExecutor) {
        LONG_EXECUTOR = longExecutor;
    }

    function execute() external {
        // Governance updates
        AAVE_GOVERNANCE_V2.setVotingDelay(VOTING_DELAY);

        address[] memory executorsToAuthorize = new address[](1);
        executorsToAuthorize[0] = LONG_EXECUTOR;
        AAVE_GOVERNANCE_V2.authorizeExecutors(executorsToAuthorize);

        // we don't call unauthorize executors just in case something goes wrong
        
        IOwnable(address(AAVE_GOVERNANCE_V2)).transferOwnership(LONG_EXECUTOR);

        // update damins
        AAVE_PROXY.changeAdmin(LONG_EXECUTOR);
        STK_AAVE_PROXY.changeAdmin(LONG_EXECUTOR);

        // we change the admin to short executor as these don't 
        // have direct effect on governance, so no need to have them on long executor
        ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
        STK_ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
    }
}

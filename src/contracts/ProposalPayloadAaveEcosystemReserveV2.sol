// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { AaveEcosystemReserveV2 } from "./AaveEcosystemReserveV2.sol";

contract ProposalPayloadAaveEcosystemReserveV2 {
    address public immutable AAVE_ECOSYSTEM_RESERVE_V2_IMPL;
    uint256 public immutable PROPOSAL_ID;
    address public constant AAVE_GOVERNANCE_V2 =
        0xEC568fffba86c094cf06b22134B23074DFE2252c;
    address public constant ECOSYSTEM_PROXY_ADDRESS = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    IInitializableAdminUpgradeabilityProxy public constant ecosystemProxy =
        IInitializableAdminUpgradeabilityProxy(
            ECOSYSTEM_PROXY_ADDRESS
        );

    constructor(address aaveEcosystemReserveV2Impl, uint256 proposalId) {
        AAVE_ECOSYSTEM_RESERVE_V2_IMPL = aaveEcosystemReserveV2Impl;
        PROPOSAL_ID = proposalId;
    }

    function execute() external {
        ecosystemProxy.upgradeToAndCall(
            AAVE_ECOSYSTEM_RESERVE_V2_IMPL,
            abi.encodeWithSignature(
                "initialize(uint256,address)",
                PROPOSAL_ID,
                AAVE_GOVERNANCE_V2
            )
        );
    }
}

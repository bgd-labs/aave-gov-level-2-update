// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {IStreamable} from './AaveEcosystemReserveV2.sol';

/**
 * @title ProposalPayloadAaveEcosystemReserveWithVoting
 * @author BGD Labs
 * @notice Aave Governance Proposal payload, upgrading the implementation of the AAVE Ecosystem Reserve
 * The initialize() on the new implementation allows to vote on another Aave governance proposal
 */
contract ProposalPayloadAaveEcosystemReserveWithVoting {
  address public immutable AUTONOMOUS_PROPOSAL;
  address public immutable AAVE_ECOSYSTEM_RESERVE_V2_IMPL;
  address public constant AAVE_GOVERNANCE_V2 =
    0xEC568fffba86c094cf06b22134B23074DFE2252c;

  uint256 public proposalId;

  IInitializableAdminUpgradeabilityProxy
    public constant AAVE_ECOSYSTEM_RESERVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x25F2226B597E8F9514B3F68F00f494cF4f286491
    );

  modifier onlyAutonomousProposal() {
    require(msg.sender == AUTONOMOUS_PROPOSAL, 'CALLER_NOT_AUTONOMOUS_PROPOSAL');
    _;
  }

  constructor(address aaveEcosystemReserveV2Impl, address autonomousProposal) {
    AAVE_ECOSYSTEM_RESERVE_V2_IMPL = aaveEcosystemReserveV2Impl;
    AUTONOMOUS_PROPOSAL = autonomousProposal;
  }

  /// @dev sets the level 2 proposal id, that will get voted on by this proposal
  function setLvl2ProposalId(uint256 _proposalId) external onlyAutonomousProposal {
    proposalId = _proposalId;
  }

  function execute() external {
    require(proposalId != 0, 'PROPOSAL_ID_LVL2_NOT_SET');

    AAVE_ECOSYSTEM_RESERVE_PROXY.upgradeToAndCall(
      AAVE_ECOSYSTEM_RESERVE_V2_IMPL,
      abi.encodeWithSelector(
        IStreamable(AAVE_ECOSYSTEM_RESERVE_V2_IMPL).initialize.selector,
        proposalId,
        AAVE_GOVERNANCE_V2
      )
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2, IExecutorWithTimelock, IGovernanceStrategy} from 'aave-address-book/AaveGovernanceV2.sol';

/**
 * @title AutonomousProposalsForGovAdjustments
 * @author BGD Labs
 * @dev Autonomous proposal to simplify delegation, and creation of needed proposals for governance configuration adjustments.
 * - Introduces a method that on call, will create LongExecutor proposal, and afterwards will also create the EcosystemReserve proposal
 *   needed to use the ecosystem voting power to vote on the LongExecutor Proposal.
 *   With this, anyone can delegate Proposition Power to this contract, and when it reaches enough power, anyone will be able to call
 *   `createProposalsForGovAdjustments` method to create the two proposals.
 * - `createProposalsForGovAdjustments` can only be called once, while proposals are not created. This is so proposals do not
 *   keep being created, as the contract could maintain the proposition power, while delegators do not withdraw their delegation
 * - `createProposalsForGovAdjustments` can only be called after specified date. This is to ensure that there is time to amass
 *   enough proposition power into the contract, and that users have time to prepare for the vote.
 */
contract AutonomousProposalsForGovAdjustments {
  address public immutable LVL2_PAYLOAD;
  bytes32 public immutable LVL2_IPFS_HASH;

  address public immutable RESERVE_ECOSYSTEM_PAYLOAD;
  bytes32 public immutable RESERVE_ECOSYSTEM_IPFS_HASH;

  uint256 public immutable CREATION_TIMESTAMP;

  uint256 public lvl2ProposalId;
  uint256 public ecosystemReserveProposalId;

  bool public proposalsCreated;

  constructor (address lvl2Payload, address reserveEcosystemPayload, bytes32 lvl2IpfsHash, bytes32 reserveEcosystemIpfsHash, uint256 creationTimestamp) {
    LVL2_PAYLOAD = lvl2Payload;
    LVL2_IPFS_HASH = lvl2IpfsHash;
    RESERVE_ECOSYSTEM_PAYLOAD = reserveEcosystemPayload;
    RESERVE_ECOSYSTEM_IPFS_HASH = reserveEcosystemIpfsHash;
    CREATION_TIMESTAMP = creationTimestamp;
  }

  function createProposalsForGovAdjustments() external {
    require(proposalsCreated == false, 'PROPOSALS_ALREADY_CREATED');
    require(block.timestamp > CREATION_TIMESTAMP, 'CREATION_TIMESTAMP_NOT_YET_REACHED');

    lvl2ProposalId = _createLvl2Proposal(LVL2_PAYLOAD, LVL2_IPFS_HASH);

    ecosystemReserveProposalId = _createEcosystemReserveProposal(RESERVE_ECOSYSTEM_PAYLOAD, RESERVE_ECOSYSTEM_IPFS_HASH);

    proposalsCreated = true;
  }

  function _createLvl2Proposal(address payload, bytes32 ipfsHash) internal returns (uint256) {
    require(payload != address(0), "PAYLOAD_ADDRESS_0");
    require(ipfsHash != bytes32(0), "IPFS_HASH_BYTES32_0");

    address[] memory targets = new address[](1);
    targets[0] = payload;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    return AaveGovernanceV2.GOV.create(
      IExecutorWithTimelock(AaveGovernanceV2.LONG_EXECUTOR),
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      ipfsHash
    );
  }

  function _createEcosystemReserveProposal(address payload, bytes32 ipfsHash) internal returns (uint256) {
    require(payload != address(0), "PAYLOAD_ADDRESS_0");
    require(ipfsHash != bytes32(0), "IPFS_HASH_BYTES32_0");

    require(lvl2ProposalId != 0, 'INCORRECT_LVL2_PROPOSAL_ID');

    address[] memory targets = new address[](1);
    targets[0] = payload;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute(uint256)';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(lvl2ProposalId);
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    return AaveGovernanceV2.GOV.create(
      IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR),
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      ipfsHash
    );
  }
}
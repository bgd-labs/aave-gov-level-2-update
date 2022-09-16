pragma solidity ^0.8.0;

import {AaveGovernanceV2, IExecutorWithTimelock, IGovernanceStrategy} from 'aave-address-book/AaveGovernanceV2.sol';
import {ProposalPayloadAaveEcosystemReserveWithVoting} from './ProposalPayloadAaveEcosystemReserveWithVoting.sol';


contract AutonomousGovLvl2Proposal {
  address public immutable LVL2_PAYLOAD;
  bytes32 public immutable LVL2_IPFS_HASH;

  address public immutable RESERVE_ECOSYSTEM_PAYLOAD;
  bytes32 public immutable RESERVE_ECOSYSTEM_IPFS_HASH;

  uint256 public lvl2ProposalId;
  uint256 public ecosystemReserveProposalId;

  AaveEcosystemReserveV2 public aaveEcosystemReserveV2Impl;
  ProposalPayloadAaveEcosystemReserveWithVoting public aaveEcosystemReservePayload;


  constructor (address lvl2Payload, bytes32 reserveEcosystemPayload, bytes32 lvl2IpfsHash, bytes32 reserveEcosystemIpfsHash) {
    LVL2_PAYLOAD = lvl2Payload;
    LVL2_IPFS_HASH = lvl2IpfsHash;
    RESERVE_ECOSYSTEM_PAYLOAD = reserveEcosystemPayload;
    RESERVE_ECOSYSTEM_IPFS_HASH = reserveEcosystemIpfsHash;
  }

  function createLvl2Proposal() external {
    // TODO: is there really a need to check if enough proposal power? it will get checked on proposal creation call either way
    lvl2ProposalId = _createProposal(LVL2_PAYLOAD, LVL2_IPFS_HASH, AaveGovernanceV2.LONG_EXECUTOR);

    /// @dev sets lvl2 proposal id on the ecosystem reserve payload, and creates the proposal
    ProposalPayloadAaveEcosystemReserveWithVoting(RESERVE_ECOSYSTEM_PAYLOAD).setLvl2ProposalId(lvl2ProposalId);
    ecosystemReserveProposalId = _createProposal(RESERVE_ECOSYSTEM_PAYLOAD, RESERVE_ECOSYSTEM_IPFS_HASH, AaveGovernanceV2.SHORT_EXECUTOR);
  }

  function _createProposal(address payload, bytes32 ipfsHash, address executor) internal returns (uint256) {
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
      IExecutorWithTimelock(executor),
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      ipfsHash
    );
  }
}
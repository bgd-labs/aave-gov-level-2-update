pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';

contract DeployLongExecutorProposal is Script {
    address public constant LONG_EXECUTOR_PAYLOAD = address(0); // TODO: add here the correct deployed payload
    bytes32 public constant PROPOSAL_IPFS_HASH = bytes32(0); // TODO: add here the correct proposal ipfs hash

    address[] memory targets = new address[](1);
    targets[0] = address(proposalPayloadEcosystem);
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = "execute()";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = "";
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    AaveGovernanceV2.GOV.create(
        IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR),
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls,
        IPFS_HASH
    );

}
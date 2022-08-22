// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/console.sol';
import {Script} from 'forge-std/Script.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';

library DeployProposal {
    function _deployProposal(address executor, address payload, bytes32 ipfsHash)
        internal
        returns (uint256 proposalId)
    {
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

contract DeployLongExecutorProposal is Script {
    address public constant LONG_EXECUTOR_PAYLOAD = address(0); // TODO: add here the correct deployed payload
    bytes32 public constant PROPOSAL_IPFS_HASH = bytes32(0); // TODO: add here the correct proposal ipfs hash

    function run() public {
        vm.startBroadcast();

        uint256 proposalId = DeployProposal._deployProposal(AaveGovernanceV2.LONG_EXECUTOR, LONG_EXECUTOR_PAYLOAD, PROPOSAL_IPFS_HASH);

        console.log('LongExecutor Proposal Id:', proposalId);

        vm.stopBroadcast();
    }
}

contract DeployEcosystemReserveProposal is Script {
    address public constant ECOSYSTEM_RESERVE_PAYLOAD = address(0); // TODO: add here the correct deployed payload
    bytes32 public constant PROPOSAL_IPFS_HASH = bytes32(0); // TODO: add here the correct proposal ipfs hash

    function run() public {
        vm.startBroadcast();

        uint256 proposalId = DeployProposal._deployProposal(AaveGovernanceV2.SHORT_EXECUTOR, ECOSYSTEM_RESERVE_PAYLOAD, PROPOSAL_IPFS_HASH);

        console.log('EcosystemReserve Proposal Id:', proposalId);

        vm.stopBroadcast();
    }
}
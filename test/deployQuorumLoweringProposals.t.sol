//// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
//
//import 'forge-std/Test.sol';
//import {GovHelpers, IAaveGov} from 'aave-helpers/GovHelpers.sol';
//import {DeployProposal} from '../script/DeployQuorumLoweringProposals.s.sol';
//
//contract DeployQuorumLoweringProposalTest is Test {
//    address public constant PAYLOAD = address(123);
//    bytes32 public constant PROPOSAL_IPFS_HASH = bytes32('this is the hash');
//
//    uint256 public beforeProposalCount;
//
//    function setUp() public {
//        vm.createSelectFork(vm.rpcUrl("ethereum"), 15370248);
//        beforeProposalCount = GovHelpers.GOV.getProposalsCount();
//    }
//
//    function testDeployProposalScript() public {
//        hoax(GovHelpers.AAVE_WHALE);
//        uint256 proposalId = DeployProposal._deployProposal(GovHelpers.LONG_EXECUTOR, PAYLOAD, PROPOSAL_IPFS_HASH);
//
//        assertEq(proposalId, beforeProposalCount);
//
//        IAaveGov.ProposalWithoutVotes memory deployedProposal = GovHelpers.getProposalById(proposalId);
//
//        assertEq(deployedProposal.targets[0], PAYLOAD);
//        assertEq(deployedProposal.ipfsHash, PROPOSAL_IPFS_HASH);
//        assertEq(deployedProposal.executor, GovHelpers.LONG_EXECUTOR);
//    }
//
//    function testDeployProposalScriptWithWrongPayload() public {
//        vm.expectRevert(bytes('PAYLOAD_ADDRESS_0'));
//        DeployProposal._deployProposal(GovHelpers.SHORT_EXECUTOR, address(0), PROPOSAL_IPFS_HASH);
//    }
//
//
//    function testDeployProposalScriptWithWrongIpfsHash() public {
//        vm.expectRevert(bytes('IPFS_HASH_BYTES32_0'));
//        DeployProposal._deployProposal(GovHelpers.SHORT_EXECUTOR, PAYLOAD, bytes32(0));
//    }
//
//
//}
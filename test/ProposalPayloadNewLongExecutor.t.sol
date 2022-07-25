// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import { Executor } from "../src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "../src/contracts/ProposalPayloadNewLongExecutor.sol";
import { AaveGovHelpers, IAaveGov } from "./utils/AaveGovHelpers.sol";
import { IERC20 } from "./utils/IERC20.sol";
import { IInitializableAdminUpgradeabilityProxy } from "../src/contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { IOwnable } from "../src/contracts/interfaces/IOwnable.sol";
import { IAaveGovernanceV2 } from "../src/contracts/interfaces/IAaveGovernanceV2.sol";
import { LongExecutorNewDelayProposal } from "./utils/LongExecutorNewDelayProposal.sol";

contract ProposalPayloadNewLongExecutorTest is Test {
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address internal constant AAVE_WHALE =
        address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);

    address public constant ADMIN = 0xEC568fffba86c094cf06b22134B23074DFE2252c; // GOV address
    uint256 public constant DELAY = 604800;
    uint256 public constant GRACE_PERIOD = 432000;
    uint256 public constant MINIMUM_DELAY = 604800;
    uint256 public constant MAXIMUM_DELAY = 864000;
    uint256 public constant PROPOSITION_THRESHOLD = 200;
    uint256 public constant VOTING_DURATION = 64000;
    uint256 public constant VOTE_DIFFERENTIAL = 1500;
    uint256 public constant MINIMUM_QUORUM = 1200;

    Executor public longExecutor;
    ProposalPayloadNewLongExecutor public payloadLongExecutor;

    // contracts
    IInitializableAdminUpgradeabilityProxy constant AAVE_PROXY =
        IInitializableAdminUpgradeabilityProxy(AAVE);
    IInitializableAdminUpgradeabilityProxy constant ABPT_PROXY =
        IInitializableAdminUpgradeabilityProxy(0x41A08648C3766F9F9d85598fF102a08f4ef84F84);
    IInitializableAdminUpgradeabilityProxy constant STK_AAVE_PROXY =
        IInitializableAdminUpgradeabilityProxy(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    IInitializableAdminUpgradeabilityProxy constant STK_ABPT_PROXY =
        IInitializableAdminUpgradeabilityProxy(0xa1116930326D21fB917d5A27F1E9943A9595fb47);

    function setUp() public {
        _prepareWhale();

        longExecutor = new Executor(
            ADMIN,
            DELAY,
            GRACE_PERIOD,
            MINIMUM_DELAY,
            MAXIMUM_DELAY,
            PROPOSITION_THRESHOLD,
            VOTING_DURATION,
            VOTE_DIFFERENTIAL,
            MINIMUM_QUORUM
        );

        payloadLongExecutor = new ProposalPayloadNewLongExecutor(
            address(longExecutor)
        );
    }

    function testProposal() public {
        _passLongExecutorProposal();
        _validateAdminsChanged();
        _validateGovernanceChanges();
    }

    function testPassProposalWithNewLongExecutor() public {
        _passLongExecutorProposal();
        uint256 govDelay = 7200; // blocks (every 12 sec) in a day
        uint256 newDelay = 604800;
        address newAdmin = address(912156);
        uint256 newVotingDuration = 64001;
        uint256 newDifferential = 1500;
        uint256 newQuorum = 1201;
        uint256 newPropositionThreshold = 201;

        // new proposal to change delay of long executor
        // using new long executor as proposal executor
        LongExecutorNewDelayProposal delayProposal = 
            new LongExecutorNewDelayProposal(
                address(longExecutor),
                newDelay,
                newAdmin,
                newVotingDuration,
                newDifferential,
                newQuorum,
                newPropositionThreshold
            );

        address[] memory targets = new address[](1);
        targets[0] = address(delayProposal);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = AaveGovHelpers._createProposal(
            vm,
            AAVE_WHALE,
            IAaveGov.SPropCreateParams({
                executor: address(longExecutor),
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        // move 1 day in blocks as gov has now 1 day delay between creation and start of vote
        vm.roll(block.number + govDelay + 10);

        AaveGovHelpers._passVote(vm, AAVE_WHALE, proposalId);

        // test that delay was set correctly
        hoax(address(longExecutor));
        assertEq(longExecutor.getDelay(), newDelay);
        assertEq(longExecutor.getPendingAdmin(), newAdmin);
        assertEq(longExecutor.VOTING_DURATION(), newVotingDuration);
        assertEq(longExecutor.VOTE_DIFFERENTIAL(), newDifferential);
        assertEq(longExecutor.MINIMUM_QUORUM(), newQuorum);
        assertEq(longExecutor.PROPOSITION_THRESHOLD(), newPropositionThreshold);
    }


    function _validateGovernanceChanges() internal {
        IAaveGovernanceV2 gov = IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);
        assertEq(gov.isExecutorAuthorized(address(longExecutor)), true);
        assertEq(gov.getVotingDelay(), 7200);
        assertEq(IOwnable(address(gov)).owner(), address(longExecutor));
    }

    function _validateAdminsChanged() internal {
        vm.startPrank(address(longExecutor));
        assertEq(AAVE_PROXY.admin(), address(longExecutor));
        assertEq(STK_AAVE_PROXY.admin(), address(longExecutor));
        vm.stopPrank();

        vm.startPrank(AaveGovHelpers.SHORT_EXECUTOR);
        assertEq(STK_ABPT_PROXY.admin(), AaveGovHelpers.SHORT_EXECUTOR);
        assertEq(ABPT_PROXY.admin(), AaveGovHelpers.SHORT_EXECUTOR);
        vm.stopPrank();
    }

    function _prepareWhale() internal {
        deal(AAVE, address(this), 5000000 ether);
        deal(address(this), 1 ether);
        IERC20(AAVE).transfer(AAVE_WHALE, 4000000 ether);
    }

    function _passLongExecutorProposal() internal {
        address[] memory targets = new address[](1);
        targets[0] = address(payloadLongExecutor);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = AaveGovHelpers._createProposal(
            vm,
            AAVE_WHALE,
            IAaveGov.SPropCreateParams({
                executor: AaveGovHelpers.LONG_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        AaveGovHelpers._passVote(vm, AAVE_WHALE, proposalId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import { AaveEcosystemReserveV2 } from "../src/contracts/AaveEcosystemReserveV2.sol";
import { AaveGovHelpers, IAaveGov } from "./utils/AaveGovHelpers.sol";
import { IInitializableAdminUpgradeabilityProxy } from "../src/contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { IERC20 } from "./utils/IERC20.sol";
import { Executor } from "../src/contracts/Executor.sol";
import { ProposalPayloadNewLongExecutor } from "../src/contracts/ProposalPayloadNewLongExecutor.sol";

contract AaveEcosystemReserveV2Test is Test {
    IERC20 constant AAVE_TOKEN =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address internal constant AAVE_WHALE =
        address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    uint256 public proposalId;
    address public ecosystemProxyAddress =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    IInitializableAdminUpgradeabilityProxy ecosystemProxy;
    AaveEcosystemReserveV2 aaveEcosystemReserveImpl;

    uint256 public votingPower;

    event VoteEmitted(
        uint256 id,
        address indexed voter,
        bool support,
        uint256 votingPower
    );

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 15370248);

        aaveEcosystemReserveImpl = new AaveEcosystemReserveV2();

        ecosystemProxy = IInitializableAdminUpgradeabilityProxy(
            ecosystemProxyAddress
        );

        proposalId = _createMockProposal();
        votingPower = AAVE_TOKEN.balanceOf(ecosystemProxyAddress);
    }

    function testGovernanceVote() public {
        vm.roll(block.number + 1);
        vm.startPrank(AaveGovHelpers.SHORT_EXECUTOR);

        vm.expectEmit(true, false, false, true);
        emit VoteEmitted(proposalId, ecosystemProxyAddress, true, votingPower);

        ecosystemProxy.upgradeToAndCall(
            address(aaveEcosystemReserveImpl),
            abi.encodeWithSignature(
                "initialize(uint256,address)",
                proposalId,
                address(AaveGovHelpers.GOV)
            )
        );

        vm.stopPrank();
    }

    function _createMockProposal() internal returns (uint256) {
        Executor longExecutor = new Executor(
            address(1234),
            604800,
            432000,
            604800,
            864000,
            200,
            64000,
            1500,
            1200
        );
        ProposalPayloadNewLongExecutor proposalPayload = new ProposalPayloadNewLongExecutor(
            address(longExecutor)
        );

        address[] memory targets = new address[](1);
        targets[0] = address(proposalPayload);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 id = AaveGovHelpers._createProposal(
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

        return id;
    }
}

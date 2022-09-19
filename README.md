# Aave Governance. Update of Level 2 governance requirements

Repository containing the necessary smart contracts to propose a change of governance requirements, mainly related with Level 2 permissions.
In addition, this repository also includes the implementation of a complementary proposal (to be executed on Level 1) that will allow the community to "boost" the voting on Level 2 with the AAVE tokens on the AAVE ecosystem reserve.
Extensive information about the proposal can be found on the Aave governance forum [https://governance.aave.com/t/rfc-aave-governance-adjust-level-2-requirements-long-executor/8693](https://governance.aave.com/t/rfc-aave-governance-adjust-level-2-requirements-long-executor/8693).

## Terminology
- **Aave Governance**. Set of smart contracts managing the control over the whole AAVE ecosystem, in a fully decentralized way via participation of AAVE token holders. The current version is V2, so frequently addresses as AaveGovernanceV2 (core smart contract of the system).
- **Level 1 (also referred as Short Executor)**. Sub-set of permissions over other systems held by the Aave governance, together with the smart contract holding them. The systems controlled DON'T HAVE recursive influence on governance processes.
- **Level 2 (also referred as Long Executor)**. Sub-set of permissions over other systems held by the Aave governance, together with the smart contract holding them. The systems controlled HAVE recursive influence over governance processes.
- **Executors/Timelocks**. Smart contracts factually holding all permissions of the Aave ecosystem and controlled by the Aave Governance; one for Level 1 and another for Level 2.
- **AAVE ecosystem reserve**. Smart contract holding AAVE for allocations by the community. Mainly used to provide funds for rewards on the Safety Module, LM program on Aave V2 Ethereum and distribution of governance power to entities that engage with the Aave community.

## Changes on the Aave Governance
On Level 2/Long-Executor the update is as follows:
- **Quorum**: 20% -> 6.5%
- **Differential**: 15% -> 6.5%
- **Proposition power required for proposal creation**: 2% -> 1.25%

Additionally, a delay of 7200 blocks (using 12s per block) between proposal creation and proposal voting is set. Before there was no delay.

## Implementations

### New contracts to be deployed

On the [contracts](/src/contracts) folder we can find the Solidity smart contracts needed to apply the governance changes:

- [AaveEcosystemReserveV2](/src/contracts/AaveEcosystemReserveV2.sol): This contract has the logic to vote on a specific proposal with the AAVE ecosystem reserve voting power. In order to have this as one-time action, the voting logic is included into the `initialize()` function. This is done to be able to more easily pass the Level 2 proposal, as that will require 20% of total voting power, and the ecosystem reserve has 10% of it approx.
This is a relatively simple update of an implementation under a transparent proxy contract, and the diff between the new implementation and the current one operating on Ethereum can be found [HERE](./diffs/AaveEcosystemReserveV2-diff.md).

- [Executor](/src/contracts/Executor.sol): This contract has the same logic as the current [Level 2/Long Executor](https://etherscan.io/address/0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7) but changing the MINIMUM_QUORUM to the new 6.5% value. It also contains methods to update the settings, so in the future there is no need to deploy new long executors. The diff between the new executor and the current one operating on Ethereum can be found [HERE](./diffs/Executor-diff.md)


### Governance Payloads

For the long executor parameters to be changed we created two proposals:

[ProposalPayloadNewLongExecutor](/src/contracts/ProposalPayloadNewLongExecutor.sol)
- Adds a delay of 7200 blocks on creation to the AaveGovernanceV2.
- Adds the new long executor as authorized executor on the Aave Governance V2.
- Moves all the Level 2 permissions affecting the governance itself from the current long executor to the new one, being:
  - Proxy admin on the [AAVE token](https://etherscan.io/address/0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)
  - Proxy admin on the AAVE Safety Module [stkAAVE token](https://etherscan.io/address/0x4da27a545c0c5B758a6BA100e3a049001de870f5)
  - Owner role on the [AaveGovernanceV2](https://etherscan.io/address/0xEC568fffba86c094cf06b22134B23074DFE2252c)
- Moves some Level 2 permissions that should be Level 1 to the current short executor, being:
  - Proxy admin on the AAVE/WETH Balancer v1 pool [ABPT](https://etherscan.io/address/0x41A08648C3766F9F9d85598fF102a08f4ef84F84)
  - Proxy admin on the ABPT Safety Module [stkABPT token](https://etherscan.io/address/0xa1116930326D21fB917d5A27F1E9943A9595fb47)
- This payload DOESN'T remove the authorization of the current long executor on AaveGovernanceV2, even after adding the new long executor. This is done for security reasons, to avoid any kind of locking of permissions if any would have been missed.
- The new long executor needs to be pre-deployed, and passed to this payload as constructor's params.

[ProposalPayloadAaveEcosystemReserveWithVoting](/src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol)
- Upgrades the implementation of the AAVE ecosystem reserve transparent proxy, and calls `initialize()` to vote on the Level 2 proposal running with `ProposalPayloadNewLongExecutor`.
- This proposal needs to be created on Level 1/Short executor after and as soon as the Level 2 proposal is created.
- Receives as constructor's params the address of the pre-deployed AAVE ecosystem reserve new implementation and the id of the proposal to vote on.


## Security
The main security guidelines followed have been:
- Changes to both the new executor and the AAVE ecosystem reserve are kept to a minimum.
- Focus on generation of diffs with the current contracts deployed on Ethereum.
- Full testing of the proposal themselves, together with checking that after they pass, the Aave governance operates normally with the new parameters.
- Validation of the code by an external team to BGD and security review by SigmaPrime and Certora.
- [Analysis](./security/Analysis%20of%20Level%202%20executor%20permissions.md) of the permissions that need to be assigned to the new executor.

## Setup
### Install

To install and execute the project locally, you need:

- ```npm install``` : As there are some scripts to make deployment easier.
- ```forge install``` : This project is made using [Foundry](https://book.getfoundry.sh/) so to run it you will need to install it, and then install its dependencies.

It is also needed to copy `.env.example` to `.env` and fill:

```
ETHERSCAN_API_KEY= // used to verify contracts against etherscan
PRIVATE_KEY= // used to deploy contracts using private key
RPC_URL= // rpc url where the contracts will be deployed
```

### Build

```
forge build
```

### Tests

```
➜ forge test
```

### Deploy

As this process will have two steps (LongExecutor, and EcosystemReserve) an [AutonomousProposal contract](./src/contracts/AutonomousProposalsForGovAdjustments.sol) has been created. 
This contract has been created, so users can delegate its proposition power to the contract, and then, when enough proposition has been delegated, anyone will be able to call the contract method:
- `createProposalsForGovAdjustments`: This method will create the proposal for the new LongExecutor, and use this proposal id to create the proposal for the EcosystemReserve, that will use its
  voting power to vote `yes` on the LongExecutor proposal.
This was done, so both steps can happen seamlessly, and for ease of proposition power gathering, as two proposals need to be created for the Governance necessary adjustments.

To deploy the necessary payloads and proposal creations, a [Makefile](Makefile) was created, with the following commands:

- [DeployGovLvl2Proposals](/script/DeployGovLvl2Proposals.s.sol): `make deploy-autonomous-proposal-<ledger|pk>`

Use `ledger` or `pk` depending on the deployment method

### Verify

The deployment scripts already try to verify the contracts against Etherscan. But the verification process can get stuck sometimes. If so try executing these commands, which will retry the verification process:
- [DeployGovLvl2Proposals](/script/DeployGovLvl2Proposals.s.sol): `make verify-autonomous-proposal-payload`

### Copyright

2022 BGD Labs
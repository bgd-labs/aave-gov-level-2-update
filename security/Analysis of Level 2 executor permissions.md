# Update of Aave Level 2 parameters. Analysis of Level 2 executor permissions

## Problem Statement

The [Aave Governance RFC & Snapshot](https://snapshot.org/#/aave.eth/proposal/0x296983800a2f7bd6227dda45a106e40e759a75e1c908456af4c2f6d6f668c540) approved by the community involves the deployment and whitelisting of a new Level 2 Executor (Long executor). One of the most critical aspects of this is the migration of all the permissions from the currently active Level 2 Executor, to the new one.

Due to how smart contracts usually manage permissions, and specifically in the case of Aave, it is not a completely straightforward task to index all the permissions a contract like the Level 2 Executor holds.

This document describes the solution we implemented.

## Solution

From our expertise on Aave contracts, we had in mind mainly 2 types of permissions the current Level 2 executor holds: **proxy admin** (*Transparent Proxy*) and **ownership** (*Ownable*). But as we should not only trust in our expertise, we looked for a solution in the market that would allow verification.

To search for contracts where the current long executor has permissions, we’ve decided to use [Trueblocks](https://trueblocks.io/) - a local-first tool for indexing appearances of an address for EVM-compatible chains. Due to its “local” nature, it is blazingly fast and therefore can dive deeper into blocks in querying blockchain data; not only *to*, *from* and *event sender* are checked, but also event topics, input data, reverted transactions, and many other edge-cases (some details [here](https://trueblocks.io/blog/indexing-addresses-on-the-ethereum-blockchain/)). It comes along with an easy-to-use command line

The search for appearances of the Level 2 Executor (Long Executor) address gave us 9 occurrences in the following transactions:

- List of the transactions inside
    
    
    | hash | block number | index |
    | --- | --- | --- |
    | 0x2006a1bf79e9169ab02f634dcedef31cfdc9b095026e566dab40fdfd605f64e1 | 11427484 | 49 |
    | 0x86af2695c4095ad78eab6bc2e0dcf6a648673bec8966cbe1ca8d3cadeca0b264 | 11432501 | 101 |
    | 0xb64d8c148d267bd59ae6627b6f94e6bd1ee9ffef0b090a65211a9f2204873f2a | 11451032 | 215 |
    | 0x558fa06a670098a995ad9b8c5496d135a8319b65fd9aad399d87d9f64cc62006 | 11451221 | 57 |
    | 0x82f97a85faa5801c4464d950404c212aff29048a41e0808dfc3dd2d862457c05 | 11824715 | 136 |
    | 0x4a7a1f6aa946ce493180244b30972dd0b2aa35ad90281ae669bcbe37212c98b0 | 12375727 | 126 |
    | 0x8a5d3b9ca8d3fb48256b2f342c3bcb5af24637fc6c35f1dc2f9f42abcb926135 | 12440535 | 40 |
    | 0x3c0062297d6e775948a15004f6bab8117df828e9db9a0b31cd4b570d4a5c56c0 | 12485690 | 20 |
    | 0x2baa131d2268216fe6173acd1910a0baa12b4792db340b6e585d22ee75bed0be | 13419950 | 43 |

As search only gives us appearances, not the data itself, we analyzed each transaction individually using Etherscan for particular places where the Level 2 Executor appeared.

The first three transactions were deployment and initial setup of the contract. Afterwards, we’ve found several *QueuedAction* events emitted by the long executor itself and a few *ProposalCreated*, *AdminChanged,* and *OwnershipTransferred* logs. (e.g. [this one](https://etherscan.io/tx/0x558fa06a670098a995ad9b8c5496d135a8319b65fd9aad399d87d9f64cc62006#eventlog) or [this](https://etherscan.io/tx/0xb64d8c148d267bd59ae6627b6f94e6bd1ee9ffef0b090a65211a9f2204873f2a#eventlog))

[https://www.notion.so](https://www.notion.so)

![Untitled](Update%20of%20Aave%20Level%202%20parameters%20Analysis%20of%20Leve%203005f8e82005465f9e68cb10b9611767/Untitled.png)

All the contracts where the Level 2 Executor became new admin and the ones, where it appeared as an emitter or just in calldata, were double-checked using the following code (proxy admin slot is `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`):

```jsx
const getStorageSlot = async (address: string, slot: string) => {
  const { providerUrl } = config.url;
  const provider = new providers.StaticJsonRpcProvider(providerUrl);

  const res = await provider.getStorageAt(address, slot);

  console.log('res ===> ', res);
};
```

## Results

Finally, four contracts were acknowledged as ones with Long executor as the proxy admin:

[0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9](https://etherscan.io/address/0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9) (AAVE)

[0x4da27a545c0c5b758a6ba100e3a049001de870f5](https://etherscan.io/address/0x4da27a545c0c5b758a6ba100e3a049001de870f5) (stkAAVE)

[0x41a08648c3766f9f9d85598ff102a08f4ef84f84](https://etherscan.io/address/0x41a08648c3766f9f9d85598ff102a08f4ef84f84) (ABPT)

[0xa1116930326d21fb917d5a27f1e9943a9595fb47](https://etherscan.io/address/0xa1116930326d21fb917d5a27f1e9943a9595fb47) (stkABPT)

And as the owner:

[0xEC568fffba86c094cf06b22134B23074DFE2252c](https://etherscan.io/address/0xec568fffba86c094cf06b22134b23074dfe2252c) (Governance V2)
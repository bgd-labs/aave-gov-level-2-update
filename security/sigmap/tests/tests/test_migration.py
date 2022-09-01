from eth_abi import encode_abi

# Helper test to setup contracts
def test_setup(
    constants,
    aave_governance_v2,
    short_executor,
    long_executor,
    aave_token_proxy,
    abpt_proxy,
    stk_aave_proxy,
    stk_abpt_proxy,
):
    assert aave_governance_v2.NAME() == "Aave Governance v2"
    assert aave_governance_v2.owner() == long_executor
    assert aave_governance_v2.isExecutorAuthorized(short_executor) == True
    assert aave_governance_v2.isExecutorAuthorized(long_executor) == True
    assert aave_governance_v2.getVotingDelay() == 0
    assert aave_governance_v2.getProposalsCount() == 92

    # Short Executor State
    assert short_executor.GRACE_PERIOD() == 432000
    assert short_executor.MINIMUM_DELAY() == 86400
    assert short_executor.MAXIMUM_DELAY() == 864000
    assert short_executor.MINIMUM_QUORUM() == 200
    assert short_executor.ONE_HUNDRED_WITH_PRECISION() == 10000
    assert short_executor.PROPOSITION_THRESHOLD() == 50
    assert short_executor.VOTE_DIFFERENTIAL() == 50
    assert short_executor.VOTING_DURATION() == 19200
    assert short_executor.getAdmin() == aave_governance_v2
    assert short_executor.getDelay() == 86400
    assert short_executor.getMinimumPropositionPowerNeeded(aave_governance_v2, 15265830) == 80000000000000000000000
    assert short_executor.getMinimumVotingPowerNeeded(0) == 0
    assert short_executor.getPendingAdmin() == constants.ZERO_ADDRESS
    assert short_executor.isActionQueued(bytes(32)) == False
    assert short_executor.isProposalOverGracePeriod(aave_governance_v2, 1) == True
    assert short_executor.isProposalPassed(aave_governance_v2, 1) == True
    assert short_executor.isPropositionPowerEnough(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == False
    assert short_executor.isQuorumValid(aave_governance_v2, 1) == True
    assert short_executor.isVoteDifferentialValid(aave_governance_v2, 1) == True
    assert short_executor.validateCreatorOfProposal(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == False
    assert short_executor.validateProposalCancellation(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == True
    
    # Long Executor State
    assert long_executor.GRACE_PERIOD() == 432000
    assert long_executor.MINIMUM_DELAY() == 604800
    assert long_executor.MAXIMUM_DELAY() == 864000
    assert long_executor.MINIMUM_QUORUM() == 2000
    assert long_executor.ONE_HUNDRED_WITH_PRECISION() == 10000
    assert long_executor.PROPOSITION_THRESHOLD() == 200
    assert long_executor.VOTE_DIFFERENTIAL() == 1500
    assert long_executor.VOTING_DURATION() == 64000
    assert long_executor.getAdmin() == aave_governance_v2
    assert long_executor.getDelay() == 604800
    assert long_executor.getMinimumPropositionPowerNeeded(aave_governance_v2, 15265830) == 320000000000000000000000
    assert long_executor.getMinimumVotingPowerNeeded(0) == 0
    assert long_executor.getPendingAdmin() == constants.ZERO_ADDRESS
    assert long_executor.isActionQueued(bytes(32)) == False
    assert long_executor.isProposalOverGracePeriod(aave_governance_v2, 1) == True
    assert long_executor.isProposalPassed(aave_governance_v2, 1) == False
    assert long_executor.isPropositionPowerEnough(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == False
    assert long_executor.isQuorumValid(aave_governance_v2, 1) == False
    assert long_executor.isVoteDifferentialValid(aave_governance_v2, 1) == False
    assert long_executor.validateCreatorOfProposal(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == False
    assert long_executor.validateProposalCancellation(aave_governance_v2, constants.ZERO_ADDRESS, 15265830) == True
    
    # Proxies
    assert aave_token_proxy.admin.call({'from': long_executor}) == long_executor
    assert abpt_proxy.admin.call({'from': long_executor}) == long_executor
    assert stk_aave_proxy.admin.call({'from': long_executor}) == long_executor
    assert stk_abpt_proxy.admin.call({'from': long_executor}) == long_executor


# Tests full migration process
# a) Deploy new long `Executor`
# b) Deploy first proposal contract `ProposalPayloadNewLongExecutor`
# c) `create()` the `ProposalPayloadNewLongExecutor` on `AaveGovernanceV2`
# d) Deploy `AaveEcosystemReserveV2` and `ProposalPayloadAaveEcosystemReserveWithVoting`
# e) `create()` the `ProposalPayloadAaveEcosystemReserveWithVoting` on `AaveGovernanceV2`
# f) Vote, queue and execute `ProposalPayloadAaveEcosystemReserveWithVoting`
# g) Create, vote, queue and execute a new proposal on the new executor to ensure it works
# Note: this test is very slow as we need to mine 19,200 + 5,600 + 39,000 + 40,000 blocks
def test_governance_migration(
    accounts,
    chain,
    constants,
    web3,
    aave_governance_v2,
    governance_strategy,
    short_executor,
    long_executor,
    aave_token_proxy,
    abpt_proxy,
    stk_aave_proxy,
    stk_abpt_proxy,
    aave_ecosystem_reserve_proxy,
    top_aave_holders,
    AaveEcosystemReserveV2,
    Executor,
    ProposalPayloadNewLongExecutor,
    ProposalPayloadAaveEcosystemReserveWithVoting,
):
    # Deploy `Executor` as the new long executor
    new_long_executor = accounts[0].deploy(
        Executor,
        aave_governance_v2, # admin
        constants.DAY, # delay
        5 * constants.DAY, # gracePeriod
        constants.DAY, # minimumDelay
        10 * constants.DAY, # maximumDelay
        125, # propositionThreshold (1.25%)
        64_000, # voteDuration (64,000 blocks)
        650, # voteDifferential (6.5%)
        650, # minimumQuorum
    )

    # Fetch the current proposal count before it's updated
    proposal_id_long = aave_governance_v2.getProposalsCount()

    # Deploy the `ProposalPayloadNewLongExecutor`
    proposal_long_executor = accounts[0].deploy(
        ProposalPayloadNewLongExecutor,
        new_long_executor
    )

    # `create()` for `ProposalPayloadNewLongExecutor`
    values = [0]
    targets = [proposal_long_executor]
    signatures = ['execute()']
    calldatas = [b'']
    with_delegate_calls = [True]
    ipfs_hash_long = b'\x12' * 32
    creator_long = top_aave_holders[3]
    tx = aave_governance_v2.create(
        long_executor,
        targets,
        values,
        signatures,
        calldatas,
        with_delegate_calls,
        ipfs_hash_long,
        {'from': creator_long}
    )

    # Validate `ProposalCreated` event
    start_block_long = tx.block_number
    end_block_long = start_block_long + 64_000
    assert tx.events['ProposalCreated']['id'] == proposal_id_long
    assert tx.events['ProposalCreated']['creator'] == creator_long
    assert tx.events['ProposalCreated']['executor'] == long_executor
    assert tx.events['ProposalCreated']['targets'] == targets
    assert tx.events['ProposalCreated']['values'] == values
    assert tx.events['ProposalCreated']['signatures'] == signatures
    assert tx.events['ProposalCreated']['calldatas'] == ['0x']
    assert tx.events['ProposalCreated']['withDelegatecalls'] == with_delegate_calls
    assert tx.events['ProposalCreated']['startBlock'] == start_block_long
    assert tx.events['ProposalCreated']['endBlock'] == end_block_long
    assert tx.events['ProposalCreated']['strategy'] == governance_strategy
    assert tx.events['ProposalCreated']['ipfsHash'] == '0x' + ipfs_hash_long.hex()

    fetched_proposal = aave_governance_v2.getProposalById(proposal_id_long)
    assert fetched_proposal['id'] == proposal_id_long
    assert fetched_proposal['creator'] == creator_long
    assert fetched_proposal['executor'] == long_executor
    assert fetched_proposal['targets'] == targets
    assert fetched_proposal['values'] == values
    assert fetched_proposal['signatures'] == signatures
    assert fetched_proposal['calldatas'] == ['0x']
    assert fetched_proposal['withDelegatecalls'] == [True]
    assert fetched_proposal['startBlock'] == start_block_long
    assert fetched_proposal['endBlock'] == end_block_long
    assert fetched_proposal['executionTime'] == 0
    assert fetched_proposal['forVotes'] == 0
    assert fetched_proposal['againstVotes'] == 0
    assert fetched_proposal['executed'] == False
    assert fetched_proposal['canceled'] == False
    assert fetched_proposal['strategy'] == governance_strategy
    assert fetched_proposal['ipfsHash'] == '0x' + ipfs_hash_long.hex()

    # Deploy the updated `AaveEcosystemReserveV2`
    aave_ecosystem_reserve_v2 = accounts[0].deploy(AaveEcosystemReserveV2)

    # Deploy the `ProposalPayloadAaveEcosystemReserveWithVoting`
    proposal_reserve_with_voting = accounts[0].deploy(
        ProposalPayloadAaveEcosystemReserveWithVoting,
        aave_ecosystem_reserve_v2,
        proposal_id_long,
    )

    # `create()` for `ProposalPayloadAaveEcosystemReserveWithVoting`
    values = [0]
    targets = [proposal_reserve_with_voting]
    signatures = ['execute()']
    calldatas = [b'']
    with_delegate_calls = [True]
    ipfs_hash_short = b'\xab' * 32
    creator_short = top_aave_holders[0] # Using aAAVE contract as creator to reach 2% requirement
    tx = aave_governance_v2.create(
        short_executor,
        targets,
        values,
        signatures,
        calldatas,
        with_delegate_calls,
        ipfs_hash_short,
        {'from': creator_short}
    )

    # Validate creating proposal
    proposal_id_reserve = proposal_id_long + 1
    start_block_reserve = tx.block_number
    end_block_reserve = tx.block_number + 19_200

    assert tx.events['ProposalCreated']['id'] == proposal_id_reserve
    assert tx.events['ProposalCreated']['creator'] == creator_short
    assert tx.events['ProposalCreated']['executor'] == short_executor
    assert tx.events['ProposalCreated']['targets'] == [proposal_reserve_with_voting]
    assert tx.events['ProposalCreated']['values'] == [0]
    assert tx.events['ProposalCreated']['signatures'] == ['execute()']
    assert tx.events['ProposalCreated']['calldatas'] == ['0x']
    assert tx.events['ProposalCreated']['withDelegatecalls'] == [True]
    assert tx.events['ProposalCreated']['startBlock'] == start_block_reserve
    assert tx.events['ProposalCreated']['endBlock'] == end_block_reserve
    assert tx.events['ProposalCreated']['strategy'] == governance_strategy
    assert tx.events['ProposalCreated']['ipfsHash'] == '0x' + ipfs_hash_short.hex()

    fetched_proposal = aave_governance_v2.getProposalById(proposal_id_reserve)
    assert fetched_proposal['id'] == proposal_id_reserve
    assert fetched_proposal['creator'] == creator_short
    assert fetched_proposal['executor'] == short_executor
    assert fetched_proposal['targets'] == [proposal_reserve_with_voting]
    assert fetched_proposal['values'] == [0]
    assert fetched_proposal['signatures'] == ['execute()']
    assert fetched_proposal['calldatas'] == ['0x']
    assert fetched_proposal['withDelegatecalls'] == [True]
    assert fetched_proposal['startBlock'] == start_block_reserve
    assert fetched_proposal['endBlock'] == end_block_reserve
    assert fetched_proposal['executionTime'] == 0
    assert fetched_proposal['forVotes'] == 0
    assert fetched_proposal['againstVotes'] == 0
    assert fetched_proposal['executed'] == False
    assert fetched_proposal['canceled'] == False
    assert fetched_proposal['strategy'] == governance_strategy
    assert fetched_proposal['ipfsHash'] == '0x' + ipfs_hash_short.hex()

    # Both proposal are now created we may begin voting. Vote on `ProposalPayloadAaveEcosystemReserveWithVoting` first.
    aave_governance_v2.submitVote(proposal_id_reserve, True, {'from': top_aave_holders[-1]})
    aave_governance_v2.submitVote(proposal_id_reserve, True, {'from': top_aave_holders[-2]})
    aave_governance_v2.submitVote(proposal_id_reserve, True, {'from': top_aave_holders[-3]})
    aave_governance_v2.submitVote(proposal_id_reserve, True, {'from': top_aave_holders[-4]})
    aave_governance_v2.submitVote(proposal_id_reserve, True, {'from': top_aave_holders[-5]})

    # Pass time and blocks such that reserve proposal is succeeded but long vote is still active
    print('Mining', 19_201, 'blocks')
    chain.mine(19_201, timedelta=19_201 * 15)

    assert aave_governance_v2.getProposalState(proposal_id_reserve) == 4 # Succeeded
    assert aave_governance_v2.getProposalState(proposal_id_long) == 2 # Active

    # Queue `ProposalPayloadAaveEcosystemReserveWithVoting`
    tx = aave_governance_v2.queue(proposal_id_reserve, {'from': accounts[0]})

    # Calculate action hash
    execution_time = tx.timestamp + 86_400
    encoded_action = encode_abi(
        [
            "address",
            "uint256",
            "string",
            "bytes",
            "uint256",
            "bool"
        ],
        [
            proposal_reserve_with_voting.address, # target
            0, # value
            'execute()', # signature
            b'', # data
            execution_time, # executionTime
            True # withDelegateCall
        ]
    )[:-32] # ignore the last 32 bytes as these are only included in certain solidity versions
    action_hash = web3.solidityKeccak(
        ['bytes'],
        [encoded_action]
    )

    # Validate queuing
    assert aave_governance_v2.getProposalState(proposal_id_reserve) == 5 # Queued
    assert tx.events['QueuedAction']['target'] == proposal_reserve_with_voting
    assert tx.events['QueuedAction']['value'] == 0
    assert tx.events['QueuedAction']['signature'] == 'execute()'
    assert tx.events['QueuedAction']['data'] == '0x'
    assert tx.events['QueuedAction']['executionTime'] == execution_time
    assert tx.events['QueuedAction']['withDelegatecall'] == True
    assert tx.events['QueuedAction']['actionHash'] == action_hash.hex()

    # Pass time and blocks such that reserve proposal is executable but long vote is still active
    print('Mining', 86_401 // 15, 'blocks')
    chain.mine(86_401 // 15, timedelta=86_401)

    # Fetch `AaveEcosystemReserve` voting power
    reserve_voting_power = governance_strategy.getVotingPowerAt(aave_ecosystem_reserve_proxy, start_block_reserve)
    
    # Execute `ProposalPayloadAaveEcosystemReserveWithVoting`
    tx = aave_governance_v2.execute(proposal_id_reserve, {'from': accounts[0]})

    # Validate proposal execution was successful
    assert tx.events['ProposalExecuted']['id'] == proposal_id_reserve
    assert tx.events['ProposalExecuted']['initiatorExecution'] == accounts[0]

    assert tx.events['ExecutedAction']['target'] == proposal_reserve_with_voting
    assert tx.events['ExecutedAction']['value'] == 0
    assert tx.events['ExecutedAction']['signature'] == 'execute()'
    assert tx.events['ExecutedAction']['executionTime'] == execution_time
    assert tx.events['ExecutedAction']['withDelegatecall'] == True
    assert tx.events['ExecutedAction']['resultData'] == '0x'
    assert tx.events['ExecutedAction']['actionHash'] == action_hash.hex()

    assert tx.events['VoteEmitted']['id'] == proposal_id_long
    assert tx.events['VoteEmitted']['voter'] == aave_ecosystem_reserve_proxy
    assert tx.events['VoteEmitted']['support'] == True
    assert tx.events['VoteEmitted']['votingPower'] == reserve_voting_power

    # Valdiate reserve proposal state
    fetched_proposal = aave_governance_v2.getProposalById(proposal_id_reserve)
    assert fetched_proposal['id'] == proposal_id_reserve
    assert fetched_proposal['creator'] == creator_short
    assert fetched_proposal['executor'] == short_executor
    assert fetched_proposal['targets'] == [proposal_reserve_with_voting]
    assert fetched_proposal['values'] == [0]
    assert fetched_proposal['signatures'] == ['execute()']
    assert fetched_proposal['calldatas'] == ['0x']
    assert fetched_proposal['withDelegatecalls'] == [True]
    assert fetched_proposal['startBlock'] == start_block_reserve
    assert fetched_proposal['endBlock'] == end_block_reserve
    assert fetched_proposal['executionTime'] == execution_time
    assert fetched_proposal['forVotes'] > 0
    assert fetched_proposal['againstVotes'] == 0
    assert fetched_proposal['executed'] == True
    assert fetched_proposal['canceled'] == False
    assert fetched_proposal['strategy'] == governance_strategy
    assert fetched_proposal['ipfsHash'] == '0x' + ipfs_hash_short.hex()

    # Validate long proposal state
    fetched_proposal = aave_governance_v2.getProposalById(proposal_id_long)
    assert fetched_proposal['id'] == proposal_id_long
    assert fetched_proposal['creator'] == creator_long
    assert fetched_proposal['executor'] == long_executor
    assert fetched_proposal['targets'] == [proposal_long_executor]
    assert fetched_proposal['values'] == [0]
    assert fetched_proposal['signatures'] == ['execute()']
    assert fetched_proposal['calldatas'] == ['0x']
    assert fetched_proposal['withDelegatecalls'] == [True]
    assert fetched_proposal['startBlock'] == start_block_long
    assert fetched_proposal['endBlock'] == end_block_long
    assert fetched_proposal['executionTime'] == 0
    assert fetched_proposal['forVotes'] == reserve_voting_power
    assert fetched_proposal['againstVotes'] == 0
    assert fetched_proposal['executed'] == False
    assert fetched_proposal['canceled'] == False
    assert fetched_proposal['strategy'] == governance_strategy
    assert fetched_proposal['ipfsHash'] == '0x' + ipfs_hash_long.hex()

    # Vote on long proposals
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[0]}) # binance
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[1]}) # binance
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[5]}) # EOA
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[6]}) # EOA
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[7]}) # EOA
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[8]}) # EOA
    aave_governance_v2.submitVote(proposal_id_long, True, {'from': top_aave_holders[9]}) # EOA

    # Pass time such that vote is now closed
    blocks_to_mine = end_block_long - chain.height + 1
    print('Mining', blocks_to_mine, 'blocks')
    chain.mine(blocks_to_mine, timedelta=blocks_to_mine * 15)

    assert aave_governance_v2.getProposalState(proposal_id_long) == 4 # Succeeded

    # Queue `ProposalPayloadAaveEcosystemReserveWithVoting`
    tx = aave_governance_v2.queue(proposal_id_long, {'from': accounts[0]})

    # Calculate action hash
    execution_time = tx.timestamp + 604_800
    encoded_action = encode_abi(
        [
            "address",
            "uint256",
            "string",
            "bytes",
            "uint256",
            "bool"
        ],
        [
            proposal_long_executor.address, # target
            0, # value
            'execute()', # signature
            b'', # data
            execution_time, # executionTime
            True # withDelegateCall
        ]
    )[:-32] # ignore the last 32 bytes as these are only included in certain solidity versions
    action_hash = web3.solidityKeccak(
        ['bytes'],
        [encoded_action]
    )

    # Validate queuing
    assert aave_governance_v2.getProposalState(proposal_id_long) == 5 # Queued
    assert tx.events['QueuedAction']['target'] == proposal_long_executor
    assert tx.events['QueuedAction']['value'] == 0
    assert tx.events['QueuedAction']['signature'] == 'execute()'
    assert tx.events['QueuedAction']['data'] == '0x'
    assert tx.events['QueuedAction']['executionTime'] == execution_time
    assert tx.events['QueuedAction']['withDelegatecall'] == True
    assert tx.events['QueuedAction']['actionHash'] == action_hash.hex()

    # Pass time and blocks such that long proposal is executable
    print('Mining', 604_800 // 15, 'blocks')
    chain.mine(604_800 // 15, timedelta=604_800)

    # Execute `ProposalPayloadAaveEcosystemReserveWithVoting`
    tx = aave_governance_v2.execute(proposal_id_long, {'from': accounts[0]})

    # Validate proposal execution was successful
    assert tx.events['ProposalExecuted']['id'] == proposal_id_long
    assert tx.events['ProposalExecuted']['initiatorExecution'] == accounts[0]

    assert tx.events['ExecutedAction']['target'] == proposal_long_executor
    assert tx.events['ExecutedAction']['value'] == 0
    assert tx.events['ExecutedAction']['signature'] == 'execute()'
    assert tx.events['ExecutedAction']['executionTime'] == execution_time
    assert tx.events['ExecutedAction']['withDelegatecall'] == True
    assert tx.events['ExecutedAction']['resultData'] == '0x'
    assert tx.events['ExecutedAction']['actionHash'] == action_hash.hex()

    # Validate proposal functionality
    assert aave_governance_v2.getVotingDelay() == 7_200
    
    assert aave_governance_v2.isExecutorAuthorized(short_executor) == True
    assert aave_governance_v2.isExecutorAuthorized(long_executor) == True
    assert aave_governance_v2.isExecutorAuthorized(new_long_executor) == True

    assert aave_governance_v2.owner() == new_long_executor
    assert aave_token_proxy.admin.call({'from': new_long_executor}) == new_long_executor
    assert stk_aave_proxy.admin.call({'from': new_long_executor}) == new_long_executor
    assert abpt_proxy.admin.call({'from': short_executor}) == short_executor
    assert stk_abpt_proxy.admin.call({'from': short_executor}) == short_executor

    assert tx.events['VotingDelayChanged']['newVotingDelay'] == 7_200
    assert tx.events['VotingDelayChanged']['initiatorChange'] == long_executor

    assert tx.events['ExecutorAuthorized']['executor'] == new_long_executor

    assert tx.events['OwnershipTransferred']['previousOwner'] == long_executor
    assert tx.events['OwnershipTransferred']['newOwner'] == new_long_executor

    # Events occur in the same order as `ProposalPayloadNewLongExecutor.execute()` (Aave, stk Aave, ABPT, stk ABPT)
    assert tx.events['AdminChanged'][0]['previousAdmin'] == long_executor
    assert tx.events['AdminChanged'][0]['newAdmin'] == new_long_executor
    assert tx.events['AdminChanged'][1]['previousAdmin'] == long_executor
    assert tx.events['AdminChanged'][1]['newAdmin'] == new_long_executor
    assert tx.events['AdminChanged'][2]['previousAdmin'] == long_executor
    assert tx.events['AdminChanged'][2]['newAdmin'] == short_executor
    assert tx.events['AdminChanged'][3]['previousAdmin'] == long_executor
    assert tx.events['AdminChanged'][3]['newAdmin'] == short_executor

    # `create()` for the new `Executor` (`setVotingDelay()`)
    new_voting_delay = 10_000

    values = [0]
    targets = [aave_governance_v2]
    signatures = [b'']
    calldatas = [aave_governance_v2.setVotingDelay.encode_input(10_000)]
    with_delegate_calls = [False]
    ipfs_hash_new = b'\xdd' * 32
    creator_long = top_aave_holders[3]
    tx = aave_governance_v2.create(
        new_long_executor,
        targets,
        values,
        signatures,
        calldatas,
        with_delegate_calls,
        ipfs_hash_new,
        {'from': creator_long}
    )

    # Validate new proposal
    proposal_id_new = proposal_id_reserve + 1
    start_block_new = tx.block_number + 7_200
    end_block_new = start_block_new + 64_000

    assert tx.events['ProposalCreated']['id'] == proposal_id_new
    assert tx.events['ProposalCreated']['creator'] == creator_long
    assert tx.events['ProposalCreated']['executor'] == new_long_executor
    assert tx.events['ProposalCreated']['targets'] == [aave_governance_v2]
    assert tx.events['ProposalCreated']['values'] == [0]
    assert tx.events['ProposalCreated']['signatures'] == ['']
    assert tx.events['ProposalCreated']['calldatas'] == [calldatas[0]]
    assert tx.events['ProposalCreated']['withDelegatecalls'] == [False]
    assert tx.events['ProposalCreated']['startBlock'] == start_block_new
    assert tx.events['ProposalCreated']['endBlock'] == end_block_new
    assert tx.events['ProposalCreated']['strategy'] == governance_strategy
    assert tx.events['ProposalCreated']['ipfsHash'] == '0x' + ipfs_hash_new.hex()

    # Pass global creation delay (set in long executor proposal)
    chain.mine(7_200, timedelta=7_200*15)
    print('Mining', 7_200, 'blocks')

    # Begin voting on new proposal
    aave_governance_v2.submitVote(proposal_id_new, True, {'from': top_aave_holders[0]})
    aave_governance_v2.submitVote(proposal_id_new, True, {'from': top_aave_holders[1]})
    aave_governance_v2.submitVote(proposal_id_new, True, {'from': top_aave_holders[2]})
    aave_governance_v2.submitVote(proposal_id_new, True, {'from': top_aave_holders[3]})
    aave_governance_v2.submitVote(proposal_id_new, True, {'from': top_aave_holders[4]})

    # Pass time such that vote is now closed
    blocks_to_mine = end_block_new - chain.height + 1
    print('Mining', blocks_to_mine, 'blocks')
    chain.mine(blocks_to_mine, timedelta=blocks_to_mine * 15)

    assert aave_governance_v2.getProposalState(proposal_id_new) == 4 # Succeeded

    # Queue new proposal
    tx = aave_governance_v2.queue(proposal_id_new, {'from': accounts[0]})

    # Validate queuing
    execution_time = tx.timestamp + constants.DAY
    assert aave_governance_v2.getProposalState(proposal_id_new) == 5 # Queued
    assert tx.events['QueuedAction']['target'] == aave_governance_v2
    assert tx.events['QueuedAction']['value'] == 0
    assert tx.events['QueuedAction']['signature'] == ''
    assert tx.events['QueuedAction']['data'] == calldatas[0]
    assert tx.events['QueuedAction']['executionTime'] == execution_time
    assert tx.events['QueuedAction']['withDelegatecall'] == False

    # Pass execution time shortcut by only mining 1 block
    chain.mine(1, timedelta=constants.DAY)

    # Execute new proposal
    tx = aave_governance_v2.execute(proposal_id_new, {'from': accounts[0]})

    # Validate proposal execution was successful
    assert tx.events['ProposalExecuted']['id'] == proposal_id_new
    assert tx.events['ProposalExecuted']['initiatorExecution'] == accounts[0]

    assert tx.events['ExecutedAction']['target'] == aave_governance_v2
    assert tx.events['ExecutedAction']['value'] == 0
    assert tx.events['ExecutedAction']['signature'] == ''
    assert tx.events['ExecutedAction']['data'] == calldatas[0]
    assert tx.events['ExecutedAction']['executionTime'] == execution_time
    assert tx.events['ExecutedAction']['withDelegatecall'] == False
    assert tx.events['ExecutedAction']['resultData'] == '0x'

    assert aave_governance_v2.getVotingDelay() == new_voting_delay
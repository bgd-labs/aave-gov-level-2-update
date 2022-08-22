build :; forge build --sizes

test :; forge test -vvv

# Deploy Payloads
deploy-long-executor-payload-ledger :; forge script script/DeployLongExecutorPayload.s.sol:DeployLongExecutorPayload --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-long-executor-payload-pk :; forge script script/DeployLongExecutorPayload.s.sol:DeployLongExecutorPayload --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-ecosystem-reserve-payload-ledger :; forge script script/DeployEcosystemReservePayload.s.sol:DeployEcosystemReservePayload --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-ecosystem-reserve-payload-pk :; forge script script/DeployEcosystemReservePayload.s.sol:DeployEcosystemReservePayload --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# verify Payloads
verify-long-executor-payload :;  forge script script/DeployLongExecutorPayload.s.sol:DeployLongExecutorPayload --rpc-url ${RPC_URL} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
verify-ecosystem-reserve-payload :;  forge script script/DeployEcosystemReservePayload.s.sol:DeployEcosystemReservePayload --rpc-url ${RPC_URL} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# Deploy Proposals
deploy-long-executor-proposal-ledger :; forge script script/DeployQuorumLoweringProposals.s.sol:DeployLongExecutorProposal --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-long-executor-proposal-pk :; forge script script/DeployQuorumLoweringProposals.s.sol:DeployLongExecutorProposal --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-ecosystem-reserve-proposal-ledger :; forge script script/DeployQuorumLoweringProposals.s.sol:DeployEcosystemReserveProposal --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-ecosystem-reserve-proposal-pk :; forge script script/DeployQuorumLoweringProposals.s.sol:DeployEcosystemReserveProposal --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

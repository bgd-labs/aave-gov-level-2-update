-include .env

build :; forge build --sizes

test :; forge test -vvv

# Deploy Payloads
deploy-autonomous-proposal-ledger :; forge script script/DeployGovLvl2Proposals.s.sol:DeployGovLvl2Proposals --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-autonomous-proposal-pk :; forge script script/DeployGovLvl2Proposals.s.sol:DeployGovLvl2Proposals --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# verify Payloads
verify-autonomous-proposal-payload :;  forge script script/DeployGovLvl2Proposals.s.sol:DeployGovLvl2Proposals --rpc-url ${RPC_URL} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

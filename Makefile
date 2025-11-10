-include .env

.PHONY: all test deploy install

build:
	forge build

test:
	forge test

install:
	forge install cyfrin/foundry-devops@0.2.2 && \
	forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && \
	forge install foundry-rs/forge-std@1.8.2 && \
	forge install transmissions11/solmate@v8.5.0

deploy-sepolia :
	@forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url $SEPOLIA_RPC_URL \
  --account myaccount \
  --broadcast \
  -vvvv

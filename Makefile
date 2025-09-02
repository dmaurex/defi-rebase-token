-include .env

.PHONY: all clean remove install update build format anvil coverage test testLocal testFork testEth deployEth deployArb bridgeEthToArb bridgeArbToEth configPools

#DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
#LOCAL_NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
ETH_SEPOLIA_NETWORK_ARGS := --rpc-url $(ETH_SEPOLIA_RPC_URL) --keystore $(ETH_SEPOLIA_KEYSTORE) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv
ARB_SEPOLIA_NETWORK_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --keystore $(ARB_SEPOLIA_KEYSTORE) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvvv

# Get config from: https://docs.chain.link/ccip/directory/testnet/chain/ethereum-testnet-sepolia
ETH_SEPOLIA_CHAIN_SELECTOR := 16015286601757825753
ARB_SEPOLIA_CHAIN_SELECTOR := 3478487238524512106
ETH_SEPOLIA_ROUTER_ADDRESS := 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
ARB_SEPOLIA_ROUTER_ADDRESS := 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165
ETH_SEPOLIA_LINK_ADDRESS := 0x779877A7B0D9E8603169DdbD7836e478b4624789
ARB_SEPOLIA_LINK_ADDRESS := 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E

all: clean remove install update build

# Clean the repo
clean :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add .

install :; forge install foundry-rs/forge-std@v1.9.7 && forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 && forge install smartcontractkit/ccip@v2.17.0-ccip1.5.16 && forge install smartcontractkit/chainlink-local@v0.2.5

# Update Dependencies
update :; forge update

build :; forge build --via-ir

format :; forge fmt

#anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

coverage :; forge coverage --report summary --ir-minimum

test :; forge test --via-ir

testLocal :; forge test --mc RebaseToken --via-ir -vv

testFork :; forge test --mc CrossChain --via-ir -vv

# Deploy to Ethereum Sepolia (rebase token, pool, vault)
deployEth:
	@forge script script/Deployer.s.sol:TokenAndPoolDeployer $(ETH_SEPOLIA_NETWORK_ARGS)
	@forge script script/Deployer.s.sol:VaultDeployer $(ETH_SEPOLIA_NETWORK_ARGS)

# Deploy to Arbitrum Sepolia (rebase token, pool) and configure the pool
deployArb:
	@forge script script/Deployer.s.sol:TokenAndPoolDeployer $(ARB_SEPOLIA_NETWORK_ARGS)

# Configure the pools on Arbitrum Sepolia and Ethereum Sepolia
# TODO: Check rate limiter configuration
configPools:
	@echo "Usage: make configPools ETH_SEPOLIA_REBASE_TOKEN_ADDRESS=0x... ARB_SEPOLIA_REBASE_TOKEN_ADDRESS=0x... ETH_SEPOLIA_POOL_ADDRESS=0x... ARB_SEPOLIA_POOL_ADDRESS=0x..."
	@forge script script/ConfigurePool.s.sol:ConfigurePoolScript \
		--sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" \
		$(ETH_SEPOLIA_POOL_ADDRESS) $(ARB_SEPOLIA_CHAIN_SELECTOR) $(ARB_SEPOLIA_POOL_ADDRESS) $(ARB_SEPOLIA_REBASE_TOKEN_ADDRESS) false 0 0 false 0 0 \
		$(ETH_SEPOLIA_NETWORK_ARGS)
	@forge script script/ConfigurePool.s.sol:ConfigurePoolScript \
		--sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" \
		$(ARB_SEPOLIA_POOL_ADDRESS) $(ETH_SEPOLIA_CHAIN_SELECTOR) $(ETH_SEPOLIA_POOL_ADDRESS) $(ETH_SEPOLIA_REBASE_TOKEN_ADDRESS) false 0 0 false 0 0 \
		$(ARB_SEPOLIA_NETWORK_ARGS)

# Bridge tokens from Ethereum Sepolia to Arbitrum Sepolia
bridgeEthToArb:
	@echo "Bridging tokens from Ethereum Sepolia to Arbitrum Sepolia..."
	@echo "Usage: make bridgeEthToArb RECEIVER=0x... TOKEN=0x... AMOUNT=X"
	@forge script script/BridgeTokens.s.sol:BridgeTokensScript \
		--sig "run(address,uint64,address,uint256,address,address)" \
		$(RECEIVER) $(ETH_SEPOLIA_CHAIN_SELECTOR) $(TOKEN) $(AMOUNT) \
		$(ETH_SEPOLIA_LINK_ADDRESS) $(ETH_SEPOLIA_ROUTER_ADDRESS) \
		$(ETH_SEPOLIA_NETWORK_ARGS)

# Bridge tokens from Arbitrum Sepolia to Ethereum Sepolia
bridgeArbToEth:
	@echo "Bridging tokens from Arbitrum Sepolia to Ethereum Sepolia..."
	@echo "Usage: make bridgeArbToEth RECEIVER=0x... TOKEN=0x... AMOUNT=X"
	@forge script script/BridgeTokens.s.sol:BridgeTokensScript \
		--sig "run(address,uint64,address,uint256,address,address)" \
		$(RECEIVER) $(ARB_SEPOLIA_CHAIN_SELECTOR) $(TOKEN) $(AMOUNT) \
		$(ARB_SEPOLIA_LINK_ADDRESS) $(ARB_SEPOLIA_ROUTER_ADDRESS) \
		$(ARB_SEPOLIA_NETWORK_ARGS)

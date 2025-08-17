## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```



forge install OpenZeppelin/openzeppelin-contracts@v5.4.0


- Known flaw: `RebaseToken.totalSupply` does not account for increase in supply due to interest. Could cause DoS when updating for that because one would need to loop through all users and sum their minted tokens including the interest
- Info: `RebaseToken.transfer` and `RebaseToken.transferFrom` needs to be implemented to prevent other users sending small amounts to another user to purposely drive down the other users interest rate
- Feature/Peculiarity: `RebaseToken.transfer` due to inheriting interest rate from sender when previously having no tokens. When wallet with low interest rate transfers to empty wallet first, and then another wallet with high interest transfers, the first wallet's interest rate is inherited. A high interest wallet should be the first to transfer to inherit the high interests... One can abuse this known feature/bug by early on minting a tiny amount in wallet A. Later on one can deposit a huge amount in wallet B. Then one can get the initially high interest rate from wallet A by transferring amount from wallet A to a fresh wallet C and then from wallet B to C -> Mitigation use the global interest rate (at the time of transfer)

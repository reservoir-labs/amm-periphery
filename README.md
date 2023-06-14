# Reservoir AMM-periphery

## Setup

### Install global dependencies

This repo uses [foundry](https://github.com/foundry-rs/foundry)
as the main tool for compiling and testing smart contracts. You can install
foundry via:

```shell
curl -L https://foundry.paradigm.xyz | bash
```

For alternative installation options & more details [see the foundry repo](https://github.com/foundry-rs/foundry).

### Install project dependencies

```bash
git submodule update --init --recursive
nvm use
npm install
npm run install 
```

## Building

```bash
forge build
```

## Testing

To run unit tests:

```bash
forge test
```

## Deploying

To deploy this onto a testnet / mainnet, run:

```bash
forge script script/setup_scaffold.s.sol --target-contract SetupScaffold 
--rpc-url "http://127.0.0.1:8545" --broadcast -vvv
```

## Contributing

Are you interested in helping us build the future of Reservoir?
Contribute in these ways:

- If you find bugs or code errors, you can open a new
  [issue ticket here.](https://github.com/reservoir-labs/amm-periphery/issues/new)

- If you find an issue and would like to submit a fix for said issue, follow
  these steps:
  - Start by forking the amm-periphery repository to your local environment.
    - Make the changes you find necessary to your local repository.
    - Submit your [pull request.](https://github.com/reservoir-labs/amm-periphery/compare)

- Have questions, or want to interact with the team and the community?
  Join our [discord!](https://discord.gg/SZjwsPT7CB)

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Add `deploy_token` support for deploying ERC20 tokens from MPC / dev-managed wallets.

## [0.5.0] - 2024-09-11

### Added
- Add Arbitrum-Mainnet support for Native transfers.
- Add optional arguments to allow setting amount for payable contract method invocations

## [0.4.0] - Skipped

## [0.3.0] - 2024-09-05

### Added

- Add support for listing address transactions.
- Add support for creating arbitrary payload signatures.
- Add support for invoking Smart Contracts using MPC and Developer-managed Wallets.

## [0.2.0] - 2024-08-28

### Added
- USDC Faucet support on Base-Sepolia
- Doc updates for staking

## [0.1.1] - 2024-08-22

### Fixed

- Incorrect stake client api being used for staking_operation.complete when calling `broadcast_staking_operation`

## [0.1.0] - 2024-08-22

- Expose all networks as constants, e.g. `Coinbase::Network::ETHEREUM_MAINNET`
- Add support for managing Webhooks.
- Add support for listing smart contract events.
- Add support for Dedicated ETH Staking for wallet addresses

### Breaking Changes
- All method signatures that took a `network_id` now take a `network` that can be either a network constant (e.g. `Coinbase::Network::BASE_MAINNET`) or a network ID (e.g.  `:base_mainnet`)

### Added

- Add to_address_id method to Transaction class
- Remove "pending" status from staking operation status

## [0.0.16] - 2024-08-14

- Add support for gasless transfers. Initially only supporting USDC sends on Base mainnet.
- Add support for list historical balances for an asset of an address.
- Add support for Ethereum-Mainnet and Polygon-Mainnet
- Add support for retrieving historical staking balances information
- Add USD value conversion details to the StakingReward object

## [0.0.14] - 2024-08-05

### Added

- Support for Shared ETH Staking for Wallet Addresses

### Changed

- `unsigned_payload`, `signed_payload`, `status`, and `transaction_hash` in-line fields on `Transfer` are deprecated in
  favor of those on `Transaction`

## [0.0.13] - 2024-07-30

### Added

- Add support for trade with MPC Server-Signer

## [0.0.10] - 2024-07-23

### Added

- Add support for Dedicated ETH Staking for external addresses
- Add support for listing validator details and fetch details of a specific validator

### Changed

- Improved accessibility for `StakingReward` and `StakingOperation` classes

## [0.0.9] - 2024-06-26

### Added

- Support external addresses for balance fetching and requesting faucet funds.
- Support for building staking operations and transactions
- Support for retrieving staking rewards information
- Add support for listing address trades via `address.trades`

### Changed

- Migrate to enumerator pattern for listing address transfers via `address.transfers`

## [0.0.8] - 2024-06-18

### Added

- Remove unused `base_sepolia_rpc_url` configuration option.
- Support assets dynamically from the backend without SDK changes.

## [0.0.7] - 2024-06-11

### Added

- Ability to trade assets from wallet and addresses
    - Note: Only supported on `base-mainnet`, not on `base-sepolia`.
- `base-mainnet` network support
    - Note: Faucet functionality is not supported.
    - Note: Server signer functionality is not yet supported.
- ServerSigner object
- Ability to get default Server-Signer

### Change

## [0.0.6] - 2024-06-03

### Added

- Server-Signer feature: ability to create wallets backed by server signers and create transfers with them.

### Changed

- Changed save_wallet to save_seed
- Changed load_wallets to load_seed and moved at wallet level

## [0.0.5] - 2024-05-20

### Added

- `wallets` method on the User class
- Ability to hydrate wallets (i.e. set the seed on it)
- Ability to create wallets backed by server signers.
    - Note: External developers cannot use this until we enable them to create and run them.

## [0.0.4] - 2024-05-13

### Changed

- Refactor methods to be more idiomatic for Ruby.

## [0.0.3] - 2024-05-08

### Added

- Allow storing seeds in local file system
- Coinbase.configure_from_file
- Faucet
- Individual private key export
- Allow disabling debug tracing
- Error specifications
- WETH ERC-20

## [0.0.2] - 2024-05-01

### Added

- Configuration via Config object
- API Key-based authentication
- API clients to use server-side architecture
- User object and default_user
- Send and receive ERC-20s

## [0.0.1] - 2024-04-19

Initial release of the Coinbase Ruby SDK. Purely client-side implementation.

### Added

- Wallet creation and export
- Address creation
- Send and receive ETH
- Supported networks: Base Sepolia

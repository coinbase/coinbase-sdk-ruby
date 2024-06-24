# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Support external addresses for balance fetching and requesting faucet funds.
- Add enumerator pattern for address.transfers and address.trades.
- Support for building staking operations and transactions
- Support for retrieving staking rewards information

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

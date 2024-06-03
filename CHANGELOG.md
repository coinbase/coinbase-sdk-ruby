# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Trade

## [0.0.5] - 2024-05-20

### [0.0.5] - 2024-06-03

- `wallets` method on the User class
- Ability to hydrate wallets (i.e. set the seed on it)
- Ability to create wallets backed by server signers.

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

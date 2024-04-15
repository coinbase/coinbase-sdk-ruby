# Coinbase Ruby SDK

The Coinbase Ruby SDK enables the simple integration of crypto into your app.
By calling Coinbase's Platform APIs, the SDK allows you to provision crypto wallets,
send crypto into/out of those wallets, track wallet balances, and trade crypto from
one asset into another.

The SDK currently supports Developer-managed Wallets using Ethereum on Base Sepolia.

**IMPORTANT: The Coinbase SDK is currently under development, and may make backwards-incompatible changes.**
**Do not use the Coinbase SDK to manage mainnet funds.**

## Documentation

[Click here for full SDK documentation](https://super-barnacle-n8zkznw.pages.github.io/)

## Installation

> Note: The gem is not published yet, the instructions below are for the future.

To use the package, run:

```bash
gem install coinbase-sdk
```

Or if you are using bundler, add the `coinbase-sdk` gem to your Gemfile:

```
gem 'coinbase-sdk'
```

Then, run:

```
bundle install
```

### Requirements

- Ruby 2.6+.

## Usage

### Sample Code Snippet

The following creates an in-memory self-custodial wallet. After the wallet is funded with ETH, it transfers 
some 100 Wei to a different wallet.

```ruby
# Initialize the SDK.
Coinbase.init

# Wallets are self-custodial with in-memory key management on Base Sepolia.
# This should NOT be used in mainnet with real funds. 
w1 = Coinbase::Wallet.new

# A wallet has a default address.
a = w1.default_address
a.to_s

# At this point, fund the wallet out-of-band using a faucet.
# Then, we can transfer 100 wei out of the wallet to another wallet.
w2 = Coinbase::Wallet.new

# We can now use the transaction hash to check the status of the transaction.
transaction_hash = w1.transfer(100, :eth, w2)
```

## Development

### Ruby Version

Developing in this repository requires Ruby >= 2.6.0. To install this on an M2 Mac,
run the [following command](https://github.com/rbenv/ruby-build/discussions/2034):

```bash
RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC rbenv install 2.6.0
```

### Set-up
Clone the repo by running:

```bash
git clone https://github.com/coinbase/coinbase-sdk-ruby.git
```

To install all dependencies, run:

```bash
bundle install
```

This SDK transitively depends on [rbsecp256k1](https://github.com/etscrivner/rbsecp256k1). Follow
[these instructions](https://github.com/etscrivner/rbsecp256k1?tab=readme-ov-file#requirements) to
ensure you have the necessary dependencies installed.

The SDK assumes the existence of a `BASE_SEPOLIA_RPCURL` environment variable defined in your .env file.
By default, this is the publicly available endpoint, which is rate-limited.
To provision your own endpoint, go to the [CDP Portal](https://portal.cloud.coinbase.com/products/base). Then
copy and paste your Base Sepolia RPC URL in the .env file:

```
BASE_SEPOLIA_RPC_URL=YOUR-URL
```

### Linting

To autocorrect all lint errors, run:

```bash
bundle exec rubocop -A
```

To detect all lint errors, run:

```bash
bundle exec rake lint
```

### Testing
To run all tests, run:

```bash
bundle exec rake test
```

To run a specific test, run (for example):

```bash
bundle exec rspec spec/coinbase/wallet_spec.rb
```

### REPL

The repository is equipped with a REPL to allow developers to play with the SDK. To start
it, run:

```bash
bundle exec bin/repl
```

### Generating Documentation

To generate documentation from the Ruby comments, run:

```bash
bundle exec yardoc --output-dir ./docs
```
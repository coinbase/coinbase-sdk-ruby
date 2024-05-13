# Coinbase Ruby SDK

The Coinbase Ruby SDK enables the simple integration of crypto into your app.
By calling Coinbase's Platform APIs, the SDK allows you to provision crypto wallets,
send crypto into/out of those wallets, track wallet balances, and trade crypto from
one asset into another.

The SDK currently supports Customer-custodied Wallets on the Base Sepolia test network.

**NOTE: The Coinbase SDK is currently in Alpha. The SDK:**

- **may make backwards-incompatible changes between releases**
- **should not be used on Mainnet (i.e. with real funds)**

Currently, the SDK is intended for use on testnet for quick bootstrapping of crypto wallets at
hackathons, code academies, and other development settings.

## Documentation

- [Platform API Documentation](https://docs.cdp.coinbase.com/platform-apis/docs/welcome)
- [Ruby SDK Documentation](https://coinbase.github.io/coinbase-sdk-ruby/)

## Installation

### In Your Ruby Project

Add the following to your Gemfile:

```
gem 'coinbase-sdk'
```

Or if you are specifying dependencies in your Gemspec:

```ruby
Gem::Specification.new do |spec|
  spec.add_runtime_dependency 'coinbase-sdk'
end
```

Then run:

```bash
bundler install
```

### In the Interactive Ruby Shell (`irb`)

On the command-line, run:

```bash
gem install coinbase-sdk
```

After running `irb`, require the Gem:

```irb
require 'coinbase'
```

### Requirements

- Ruby 2.7+.

## Usage

### Initialization

To start, [create a CDP API Key](https://portal.cdp.coinbase.com/access/api). Then, initialize the Platform SDK by passing your API Key name and API Key's private key via the `configure` method:

```ruby
api_key_name = "Copy your API Key name here."
api_key_private_key = "Copy your API Key's private key here."

Coinbase.configure do |config|
  config.api_key_name = api_key_name
  config.api_key_private_key = api_key_private_key
end
```

Another way to initialize the SDK is by sourcing the API key from the json file that contains your API key,
downloaded from CDP portal.

```ruby
Coinbase.configure_from_json('~/Downloads/coinbase_cloud_api_key.json')
```

This will allow you to authenticate with the Platform APIs and get access to the `default_user`.

```ruby
u = Coinbase.default_user
```

### Wallets, Addresses, and Transfers

Now, create a Wallet from the User. Wallets are created with a single default Address.

```ruby
# Create a Wallet with one Address by default.
w1 = u.create_wallet
```

Next, view the default Address of your Wallet. You will need this default Address in order to fund the Wallet for your first Transfer.

```ruby
# A Wallet has a default Address.
a = w1.default_address
a.to_s
```

Wallets do not have funds on them to start. In order to fund the Address, you will need to send funds to the Wallet you generated above. If you don't have testnet funds, get funds from a [faucet](https://docs.base.org/docs/tools/network-faucets/).

For development purposes, we provide a `faucet` method to fund your address with ETH on Base Sepolia testnet. We allow one faucet claim per address in a 24 hour window.

```ruby
# Create a faucet request that returns you a Faucet transaction that can be used to track the tx hash.
faucet_tx = a.faucet
faucet_tx.transaction_hash
```

```ruby
# Create a new Wallet to transfer funds to.
# Then, we can transfer 0.00001 ETH out of the Wallet to another Wallet.
w2 = u.create_wallet
w1.transfer(0.00001, :eth, w2).wait!
```

### Re-Instantiating Wallets

The SDK creates Wallets with developer managed keys, which means you are responsible for securely storing the keys required to re-instantiate Wallets. The code walks you through how to export a Wallet and store it in a secure location.

```ruby
# Optional: Create a new Wallet if you do not already have one.
# Export the data required to re-instantiate the Wallet.
w3 = u.create_wallet
data = w3.export
```

In order to persist the data for the Wallet, you will need to implement a store method to store the data export in a secure location. If you do not store the Wallet in a secure location you will lose access to the Wallet and all of the funds on it.

```ruby
# At this point, you should implement your own "store" method to securely persist
# the data required to re-instantiate the Wallet at a later time.
store(data)
```

For convenience during testing, we provide a save_wallet_locally! method that stores the Wallet data in your local file system.
This is an insecure method of storing wallet seeds and should only be used for development purposes.

```ruby
u.save_wallet_locally!(w3)
```

To encrypt the saved data, set encrypt to true. Note that your CDP API key also serves as the encryption key
for the data persisted locally. To re-instantiate wallets with encrypted data, ensure that your SDK is configured with
the same API key when invoking `save_wallet_locally!` and `load_wallets`.

```ruby
u.save_wallet_locally!(w3, encrypt: true)
```

The below code demonstrates how to re-instantiate a Wallet from the data export.

```ruby
# The Wallet can be re-instantiated using the exported data.
# w4 will be equivalent to w3.
w4 = Coinbase::Wallet.import(data)
```

To import wallets that were persisted to your local file system using `save_wallet_locally!`, use the below code.

```ruby
# The Wallet can be re-instantiated using the exported data.
# w5 will be equivalent to w3.
wallets = u.load_wallets
w5 = wallets[w3.id]
```

## Development

### Ruby Version

Developing in this repository requires Ruby >= 2.7.0. To install this on an M2 Mac,
run the [following command](https://github.com/rbenv/ruby-build/discussions/2034):

```bash
RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC rbenv install 2.7.0
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

The SDK assumes the existence of a `BASE_SEPOLIA_RPC_URL` environment variable defined in your .env file.
By default, this is the publicly available endpoint, which is rate-limited.
To provision your own endpoint, go to the [CDP Portal](https://portal.cloud.coinbase.com/products/base). Then
copy and paste your Base Sepolia RPC URL in the .env file:

```
BASE_SEPOLIA_RPC_URL=YOUR-URL
```

### Linting

To autocorrect all lint errors, run:

```bash
make format
```

To detect all lint errors, run:

```bash
make lint
```

### Testing

To run all tests, run:

```bash
make test
```

To run a specific test, run (for example):

```bash
bundle exec rspec spec/coinbase/wallet_spec.rb
```

### REPL

The repository is equipped with a REPL to allow developers to play with the SDK. To start
it, run:

```bash
make repl
```

### Generating Documentation

To generate documentation from the Ruby comments, run:

```bash
make docs
```

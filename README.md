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

## Requirements

Make sure that your developer environment satisfies all of the requirements before proceeding through the quickstart.

### Ruby 2.7+

The Coinbase server-side SDK requires Ruby 2.7 or higher. To view your currently installed version of Ruby, run
the following from the command-line:

```bash
ruby -v
```

We recommend installing and managing Ruby versions with `rbenv`.
See [Using Package Managers](https://github.com/rbenv/rbenv?tab=readme-ov-file#homebrew) in the rbenv README for instructions on how to install `rbenv`.

Once `rbenv` has been installed, you can install and use Ruby 2.7 by running the following commands:

```bash
rbenv install 2.7.0
rbenv global 2.7.0
```

### Rbsecp256k1 Gem

The Coinbase Platform SDK depends on the `rbsecp256k1` gem, which requires certain dependencies to be installed on your system. Follow the instructions provided [here](https://github.com/etscrivner/rbsecp256k1?tab=readme-ov-file#requirements) to meet these requirements:

#### MacOS

On MacOS, run the following command:

```bash
brew install automake openssl libtool pkg-config gmp libffi
```

#### Linux

On Linux, run the following command:

```
sudo apt-get install build-essential automake pkg-config libtool \
  libffi-dev libssl-dev libgmp-dev python3-dev
```

:::info
If you installed `libsecp256k1` but the gem cannot find it, run `ldconfig` to update your library load paths.
:::

### OpenSSL Gem

The Coinbase Platform SDK relies on the `openssl` gem for certain cryptographic operations. If you encounter issues installing
the Platform SDK, ensure that OpenSSL 3+ is installed, and that the version used by Ruby matches the version required by the gem.

If you encounter an error like this:

```bash
error: incomplete definition of type 'struct evp_md_ctx_st'
    pkey = EVP_PKEY_CTX_get0_pkey(EVP_MD_CTX_get_pkey_ctx(ctx));
```

re-install the openssl gem with the following command:

```bash
gem install openssl -- --with-openssl-dir=$(brew --prefix openssl@3)
```

## Installation

There are two ways of installing the Coinbase Platform SDK: for use with the Interactive Ruby Shell, or for use
in a Ruby project (e.g. Ruby on Rails).

### For `irb`

Use the Interactive Ruby Shell (`irb`) to leverage Ruby’s built-in REPL and quickly explore the functionality of our SDK.

Run the following from the command line:

```bash
gem install coinbase-sdk
```

After running `irb`, require the Gem:

```ruby
require 'coinbase'
```

### For Ruby on Rails

Alternatively, if you want to install your Coinbase SDK gem to your Ruby on Rails project, add the following line to your Gemfile:

```ruby
gem 'coinbase-sdk'
```

Or if you are using a Gemspec:

```ruby
Gem::Specification.new do |spec|
  spec.add_runtime_dependency 'coinbase-sdk'
end
```

Then run:

```bash
bundle install
```

## Creating a Wallet

To start, [create a CDP API key](https://portal.cdp.coinbase.com/access/api). Then, initialize the Platform SDK by passing your API key name and API key's private key via the `configure` method:

```ruby
api_key_name = "Copy your API key name here."
# Ensure that you are using double-quotes here.
api_key_private_key = "Copy your API key's private key here."

Coinbase.configure do |config|
  config.api_key_name = api_key_name
  config.api_key_private_key = api_key_private_key
end

puts "Coinbase SDK has been successfully configured with CDP API key."
```

Another way to initialize the SDK is by sourcing the API key from the JSON file that contains your API key,
downloaded from the CDP portal.

```ruby
Coinbase.configure_from_json('~/Downloads/cdp_api_key.json')

puts "Coinbase SDK has been successfully configured from JSON file."
```

This will allow you to [authenticate](./authentication.md) with the Platform APIs and get access to the
[`default_user`](./users.md):

```ruby
u = Coinbase.default_user
```

If you are using a CDP Server-Signer to manage your private keys, enable it with

```ruby
Coinbase.configuration.use_server_signer=true
```
Now, create a wallet from the User. Wallets are created with a single default address.

```ruby
# Create a wallet with one address by default.
w1 = u.create_wallet
```

Wallets come with a single default address, accessible via `default_address`:

```ruby
# A wallet has a default address.
a = w1.default_address
```

## Funding a Wallet

Wallets do not have funds on them to start. For Base Sepolia testnet, we provide a `faucet` method to fund your wallet with
testnet ETH. You are allowed one faucet claim per 24-hour window.

```ruby
# Fund the wallet with a faucet transaction.
faucet_tx = w1.faucet

puts "Faucet transaction successfully completed: #{faucet_tx}"
```

## Transferring Funds

See [Transfers](https://docs.cdp.coinbase.com/wallets/docs/transfers) for more information.

Now that your faucet transaction has successfully completed, you can send the funds in your wallet to another wallet.
The code below creates another wallet, and uses the `transfer` function to send testnet ETH from the first wallet to
the second:

```ruby
# Create a new wallet w2 to transfer funds to.
w2 = u.create_wallet

puts "Wallet successfully created: #{w2}"

t = w1.transfer(0.00001, :eth, w2).wait!

puts "Transfer successfully completed: #{t}"
```

## Listing Transfers

```
# Get the first transfer from the address.
address.transfers.first

# Iterate over all transfers in the address. This will lazily fetch transfers from the server.
address.transfers.each do |transfer|
  puts transfer
end

# Return array of all transfers. This will paginate and fetch all transfers for the address.
address.transfers.to_a
```

## Trading Funds

See [Trades](https://docs.cdp.coinbase.com/wallets/docs/trades) for more information.

```ruby

wallet = Coinbase::Wallet.create(network_id: "base-mainnet")

puts "Wallet successfully created: #{wallet}"
puts "Send `base-mainnet` ETH to wallets default address: #{wallet.default_address.id}"

trade = wallet.trade(0.00001, :eth, :usdc).wait!

puts "Trade successfully completed: #{trade}"
```

## Listing Trades

```
# Get the first trade from the address.
address.trades.first

# Iterate over all trades in the address. This will lazily fetch trades from the server.
address.trades.each do |trade|
  puts trade
end

# Return array of all trades. This will paginate and fetch all trades for the address.
address.trades.to_a
```

## Persisting a Wallet

The SDK creates wallets with developer managed keys, which means you are responsible for securely storing the keys required to re-instantiate wallets. The following code explains how to export a wallet and store it in a secure location.

```ruby
# Export the data required to re-instantiate the wallet.
data = w1.export
```

In order to persist the data for a wallet, you will need to implement a `store` method to store the exported data in a secure location. If you do not store the wallet in a secure location, you will lose access to the wallet, as well as the funds on it.

```ruby
# You should implement the "store" method to securely persist the data object,
# which is required to re-instantiate the wallet at a later time. For ease of use,
# the data object is converted to a Hash first.
store(data.to_hash)
```

For more information on wallet persistence, see [the documentation on wallets](./wallets.md#persisting-a-wallet).

Alternatively, you can use the `save_seed!` function to persist a wallet's seed to a local file. This is a
convenience function purely for testing purposes, and should not be considered a secure method of persisting wallets.

```ruby
# Pick a file to which to save your wallet seed.
file_path = 'my_seed.json'

# Set encrypt: true to encrypt the wallet seed with your CDP API key.
w1.save_seed!(file_path, encrypt: true)

puts "Seed for wallet #{w1.id} successfully saved to #{file_path}."
```

## Re-instantiating a Wallet

To re-instantiate a wallet, fetch your export data from your secure storage, and pass it to the `import` method:

```ruby
# You should implement the "fetch" method to retrieve the securely persisted data object,
# keyed by the wallet ID.
fetched_data = fetch(w1.id)

# w3 will be equivalent to w1.
w3 = u.import_wallet(fetched_data)
```

If you used the `save_seed!` function to persist a wallet's seed to a local file, then you can first fetch
the unhydrated wallet from the server, and then use the `load_seed` method to re-instantiate the wallet.

```ruby
# Get the unhydrated wallet from the server.
w4 = u.wallet(w1.id)

# You can now load the seed into the wallet from the local file.
# w4 will be equivalent to w1.
w4.load_seed(file_path)
```

## External Addresses

Addresses that do not belong CDP wallets can still be interacted with via the Platform SDK.

You can fetch balances, request faucet funds, and eventually construct unsigned transactions that
can be signed by the owner of the address (e.g. your user's self-custodied wallet).

See [External Addresses docs](./docs/external-addresses.md) for more information.

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

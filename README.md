# Coinbase Ruby SDK

The Coinbase Ruby SDK enables the simple integration of crypto into your app.
By calling Coinbase's Platform APIs, the SDK allows you to provision crypto wallets,
send crypto into/out of those wallets, track wallet balances, and trade crypto from
one asset into another.

## Documentation

> TODO

## Installation

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

## Usage

> TODO

## Development

### Ruby Version

Developing in this repository requires Ruby >= 2.6.0. To install this on an M2 Mac,
run the [following command](https://github.com/rbenv/ruby-build/discussions/2034):

```bash
RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC rbenv install 2.6.0
```

### Dependencies

To install all dependencies, run:

```bash
bundle install
```

This SDK transitively depends on [rbsecp256k1](https://github.com/etscrivner/rbsecp256k1). Follow
[these instructions](https://github.com/etscrivner/rbsecp256k1?tab=readme-ov-file#requirements) to
ensure you have the necessary dependencies installed.

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
# Coinbase Ruby SDK

The Coinbase Ruby SDK enables the simple integration of crypto into your app.
By calling Coinbase's Platform APIs, the SDK allows you to provision crypto wallets,
send crypto into/out of those wallets, track wallet balances, and trade crypto from
one asset into another.

## Documentation

> TODO

## Installation

> TODO

## Usage

> TODO

## Development

### Ruby Version

Developing in this repository requires Ruby >= 2.6.0. To install this on an M2 Mac,
run the [following command](https://github.com/rbenv/ruby-build/discussions/2034):

```bash
RUBY_CFLAGS=-DUSE_FFI_CLOSURE_ALLOC rbenv install 2.6.0
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
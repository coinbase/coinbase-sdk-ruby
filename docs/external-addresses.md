# External Addresses

Addresses that do not belong CDP wallets can still be interacted with via the Platform SDK.

## Construct an external address
```ruby
address = Coinbase::ExternalAddress.new(:base_sepolia, "0x123456789")
```

## Fetch Balances
```ruby
address = Coinbase::ExternalAddress.new(:base_sepolia, "0x123456789")
puts address.balances
# => { eth: 1.0, usdc: 22.0 }

puts address.balance(:usdc)
# => 22.0
```

## Request Faucet Funds
```ruby
address = Coinbase::ExternalAddress.new(:base_sepolia, "0x123456789")

faucet_tx = address.faucet
puts faucet_tx.transaction_hash
# "0xTXHASH"
```

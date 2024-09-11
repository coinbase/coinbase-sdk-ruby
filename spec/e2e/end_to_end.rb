# frozen_string_literal: true

require 'dotenv'
Dotenv.load

describe Coinbase do
  before do
    # GitHub secrets truncate newlines as whitespace, so we need to replace them.
    # See https://github.com/github/docs/issues/14207
    api_key_name = ENV['API_KEY_NAME'].gsub('\n', "\n")
    api_key_private_key = ENV['API_KEY_PRIVATE_KEY'].gsub('\n', "\n")

    # Use default API URL if not provided
    api_url = ENV.fetch('API_URL', nil)

    described_class.configure do |config|
      config.api_key_name = api_key_name
      config.api_key_private_key = api_key_private_key
      config.api_url = api_url if api_url
    end
  end

  describe 'v0.1.0 SDK' do
    it 'behaves as expected' do # rubocop:disable RSpec/NoExpectationExample
      new_address = create_new_address_test
      imported_wallet = import_wallet_test
      fetch_addresses_balances_test(imported_wallet)
      imported_address = imported_wallet.addresses[0]
      transfer_test(imported_address, new_address)
      fetch_address_historical_balances_test(imported_address)
      list_address_transactions_test(imported_address)
    end
  end

  # Use Server-Signer only half the runs to save test time.
  describe 'use for serve signer', skip: rand >= 0.5 do
    it 'behaves as expected' do # rubocop:disable RSpec/NoExpectationExample
      described_class.configuration.use_server_signer = true
      signer = Coinbase::ServerSigner.default
      puts "Using ServerSigner with ID: #{signer.id}"

      new_address = create_new_address_test
      existing_wallet = fetch_existing_wallet
      fetch_addresses_balances_test(existing_wallet)
      existing_address = existing_wallet.addresses[0]
      transfer_test(existing_address, new_address)
      fetch_address_historical_balances_test(existing_address)
      list_address_transactions_test(existing_address)
    end
  end
end

def create_new_address_test
  puts 'Creating new wallet...'
  w1 = Coinbase::Wallet.create
  expect(w1).not_to be_nil
  puts "Created new wallet with ID: #{w1.id}, default address: #{w1.default_address}"

  puts 'Creating new address...'
  new_address = w1.create_address
  expect(new_address).not_to be_nil
  puts "Created new address with ID: #{new_address.id} in wallet with ID #{w1.id}"

  new_address
end

def import_wallet_test
  data_string = ENV.fetch('WALLET_DATA', nil)
  expect(data_string).not_to be_nil
  puts 'Importing wallet with balance...'

  data_hash = JSON.parse(data_string)
  data = Coinbase::Wallet::Data.from_hash(data_hash)
  puts "imported wallet id #{data.wallet_id}"
  expect(data).not_to be_nil
  expect(data.wallet_id).not_to be_nil
  expect(data.seed).not_to be_nil

  wallet = Coinbase::Wallet.import(data)
  expect(wallet).not_to be_nil
  puts "Imported wallet with ID: #{wallet.id}, default address: #{wallet.default_address}"

  wallet
end

def fetch_addresses_balances_test(wallet)
  puts 'Listing wallet addresses...'
  addresses = wallet.addresses
  expect(addresses.length).to be > 1
  puts "Listed addresses: #{addresses.map(&:to_s).join(', ')}"

  puts 'Fetching wallet balances...'
  balances = wallet.balances
  expect(balances.length).to be >= 1
  puts "Fetched balances: #{balances}"
end

def fetch_address_historical_balances_test(address)
  puts 'Listing address historical balances...'
  historical_balances = address.historical_balances(:eth)
  expect(historical_balances.first).not_to be_nil
  puts "Most recent historical balances: #{historical_balances.first}"
end

def list_address_transactions_test(address)
  puts 'Listing address transactions...'
  txns = address.transactions
  expect(txns.first).not_to be_nil
  expect(txns.first.block_hash).not_to be_nil
  puts "Most recent transaction: #{txns.first}"
end

def transfer_test(imported_address, new_address)
  # Transfer eth from imported address to new address.
  puts 'Transferring 0.00008 Eth from imported address to new address...'
  t = imported_address.transfer(0.00008, :eth, new_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred 0.00008 eth from #{imported_address} to #{new_address}"

  # Fund the new address with faucet.
  begin
    faucet_tx = new_address.faucet
    puts "Requested faucet funds: #{faucet_tx}"
  rescue Coinbase::FaucetLimitReachedError
    puts 'Faucet has reached limit. Will continue with test'
  end

  send_amount = new_address.balance(:eth) - 1e-4 # Leave some eth for gas.

  # Transfer eth back from new address to imported address.
  t = new_address.transfer(send_amount, :eth, imported_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred #{send_amount} eth from #{new_address} to #{imported_address}"

  puts 'Fetching updated balances...'
  first_balance = imported_address.balances
  second_balance = new_address.balances
  expect(first_balance[:eth]).to be > BigDecimal('0')
  expect(second_balance[:eth]).to be > BigDecimal('0')
  puts "Imported address balances: #{first_balance}"
  puts "New address balances: #{second_balance}"
end

def fetch_existing_wallet
  # TODO: Change to using get method when available.
  data_string = ENV.fetch('SERVER_SIGNER_WALLET_DATA', nil)
  expect(data_string).not_to be_nil
  decoded_data = Base64.decode64(data_string)
  data_hash = JSON.parse(decoded_data)
  data = Coinbase::Wallet::Data.from_hash(data_hash)
  puts "imported wallet id #{data.wallet_id}"
  expect(data).not_to be_nil
  expect(data.wallet_id).not_to be_nil

  wallet = Coinbase::Wallet.import(data)
  expect(wallet).not_to be_nil

  wallet
end

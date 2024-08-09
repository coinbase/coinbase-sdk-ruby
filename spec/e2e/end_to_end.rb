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

  describe 'v0.0.9 SDK' do
    it 'behaves as expected' do # rubocop:disable RSpec/NoExpectationExample
      user = fetch_user_test
      new_address = create_new_address_test(user)
      imported_wallet = import_wallet_test(user)
      fetch_addresses_balances_test(imported_wallet)
      imported_address = imported_wallet.addresses[0]
      transfer_test(imported_address, new_address)
    end
  end

  # Use Server-Signer only half the runs to save test time.
  describe 'use for serve signer', skip: rand >= 0.5 do
    it 'behaves as expected' do # rubocop:disable RSpec/NoExpectationExample
      described_class.configuration.use_server_signer = true
      signer = Coinbase::ServerSigner.default
      puts "Using ServerSigner with ID: #{signer.id}"

      user = fetch_user_test
      new_address = create_new_address_test(user)
      existing_wallet = fetch_existing_wallet(user)
      fetch_addresses_balances_test(existing_wallet)
      existing_address = existing_wallet.addresses[0]
      transfer_test(existing_address, new_address)
    end
  end
end

def fetch_user_test
  puts 'Fetching default user...'
  user = Coinbase.default_user
  expect(user).not_to be_nil
  user
end

def create_new_address_test(user)
  puts 'Creating new wallet...'
  w1 = user.create_wallet
  expect(w1).not_to be_nil
  puts "Created new wallet with ID: #{w1.id}, default address: #{w1.default_address}"

  puts 'Creating new address...'
  new_address = w1.create_address
  expect(new_address).not_to be_nil
  puts "Created new address with ID: #{new_address.id} in wallet with ID #{w1.id}"

  new_address
end

def import_wallet_test(user)
  data_string = ENV.fetch('WALLET_DATA', nil)
  expect(data_string).not_to be_nil
  puts 'Importing wallet with balance...'

  data_hash = JSON.parse(data_string)
  data = Coinbase::Wallet::Data.from_hash(data_hash)
  puts "imported wallet id #{data.wallet_id}"
  expect(data).not_to be_nil
  expect(data.wallet_id).not_to be_nil
  expect(data.seed).not_to be_nil

  wallet = user.import_wallet(data)
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

def transfer_test(imported_address, new_address)
  # Transfer gwei from imported address to new address.
  puts 'Transferring 1 Gwei from imported address to new address...'
  t = imported_address.transfer(1, :gwei, new_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred 1 Gwei from #{imported_address} to #{new_address}"

  # Fund the new address with faucet.
  faucet_tx = new_address.faucet
  puts "Requested faucet funds: #{faucet_tx}"

  # Transfer eth back from new address to imported address.
  t = new_address.transfer(0.008, :eth, imported_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred 0.008 eth from #{new_address} to #{imported_address}"

  puts 'Fetching updated balances...'
  first_balance = imported_address.balances
  second_balance = new_address.balances
  expect(first_balance[:eth]).to be > BigDecimal('0')
  expect(second_balance[:eth]).to be > BigDecimal('0')
  puts "Imported address balances: #{first_balance}"
  puts "New address balances: #{second_balance}"
end

def fetch_existing_wallet(user)
  # TODO: Change to using get method when available.
  data_string = ENV.fetch('SERVER_SIGNER_WALLET_DATA', nil)
  expect(data_string).not_to be_nil
  decoded_data = Base64.decode64(data_string)
  data_hash = JSON.parse(decoded_data)
  data = Coinbase::Wallet::Data.from_hash(data_hash)
  puts "imported wallet id #{data.wallet_id}"
  expect(data).not_to be_nil
  expect(data.wallet_id).not_to be_nil

  wallet = user.import_wallet(data)
  expect(wallet).not_to be_nil

  wallet
end

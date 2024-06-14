# frozen_string_literal: true

require 'dotenv'
Dotenv.load

describe Coinbase do
  describe 'v0.0.7 SDK' do
    it 'behaves as expected' do
      e2e_test
    end
  end

  describe 'use serve signer' do
    it 'behaves as expected' do
      e2e_test(use_server_signer: true)
    end
  end
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def e2e_test(use_server_signer: false)
  # GitHub secrets truncate newlines as whitespace, so we need to replace them.
  # See https://github.com/github/docs/issues/14207
  api_key_name = ENV['API_KEY_NAME'].gsub('\n', "\n")
  api_key_private_key = ENV['API_KEY_PRIVATE_KEY'].gsub('\n', "\n")

  # Use default API URL if not provided
  api_url = ENV['API_URL']

  Coinbase.configure do |config|
    config.api_key_name = api_key_name
    config.api_key_private_key = api_key_private_key
    config.api_url = api_url if api_url
    config.use_server_signer = use_server_signer
  end

  puts 'Fetching default user...'
  u = Coinbase.default_user
  expect(u).not_to be_nil
  puts "Fetched default user with ID: #{u.id}"

  if use_server_signer
    signer = Coinbase::ServerSigner.default
    puts "Using ServerSigner with ID: #{signer.id}"
  end

  data_string = ENV['WALLET_DATA']
  expect(data_string).not_to be_nil

  puts 'Creating new wallet...'
  w1 = u.create_wallet
  expect(w1).not_to be_nil
  puts "Created new wallet with ID: #{w1.id}, default address: #{w1.default_address}"

  puts 'Creating new address...'
  new_address = w1.create_address
  expect(new_address).not_to be_nil
  puts "Created new address with ID: #{new_address.id} in wallet with ID #{w1.id}"

  # To move funds from imported wallet, do not use Server-Signer.
  Coinbase.configuration.use_server_signer = false

  puts 'Importing wallet with balance...'

  data_hash = JSON.parse(data_string)
  data = Coinbase::Wallet::Data.from_hash(data_hash)
  puts "imported wallet id #{data.wallet_id}"
  expect(data).not_to be_nil
  expect(data.wallet_id).not_to be_nil
  expect(data.seed).not_to be_nil

  w2 = u.import_wallet(data)
  expect(w2).not_to be_nil
  puts "Imported wallet with ID: #{w2.id}, default address: #{w2.default_address}"

  puts 'Listing wallet addresses...'
  addresses = w2.addresses
  expect(addresses.length).to be > 1
  puts "Listed addresses: #{addresses.map(&:to_s).join(', ')}"

  puts 'Fetching wallet balances...'
  balances = w2.balances
  expect(balances.length).to be >= 1
  puts "Fetched balances: #{balances}"

  puts 'Transfering 1 Gwei from imported address to new address...'
  imported_address = addresses[0]

  # Transfer gwei from imported address to new address.
  t = imported_address.transfer(1, :gwei, new_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred 1 Gwei from #{imported_address} to #{new_address}"

  # Transfer some eth for gas fee to new address.
  t2 = imported_address.transfer(0.00000003, :eth, new_address).wait!
  expect(t2.status).to eq('complete')
  puts "Transferred 0.00000003 Eth from #{imported_address} to #{new_address}"

  # Use Server-Signer if needed for newly created wallet.
  Coinbase.configuration.use_server_signer = use_server_signer

  # Transfer gwei back from new address to imported address.
  t = new_address.transfer(1, :gwei, imported_address).wait!
  expect(t.status).to eq('complete')
  puts "Transferred 1 Gwei from #{new_address} to #{imported_address}"

  puts 'Fetching updated balances...'
  first_balance = imported_address.balances
  second_balance = new_address.balances
  expect(first_balance[:eth]).to be > BigDecimal('0')
  expect(second_balance[:eth]).to be > BigDecimal('0')
  puts "Imported address balances: #{first_balance}"
  puts "New address balances: #{second_balance}"
end

# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

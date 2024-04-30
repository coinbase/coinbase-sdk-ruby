# frozen_string_literal: true

require 'dotenv'
Dotenv.load

describe Coinbase do
  describe 'v0.0.2 SDK' do
    it 'behaves as expected' do
      # GitHub secrets truncate newlines as whitespace, so we need to replace them.
      # See https://github.com/github/docs/issues/14207
      api_key_name = ENV['API_KEY_NAME'].gsub('\n', "\n")
      api_key_private_key = ENV['API_KEY_PRIVATE_KEY'].gsub('\n', "\n")
      Coinbase.configure do |config|
        config.api_key_name = api_key_name
        config.api_key_private_key = api_key_private_key
      end

      puts 'Fetching default user...'
      u = Coinbase.default_user
      expect(u).not_to be_nil
      puts "Fetched default user with ID: #{u.user_id}"

      puts 'Creating new wallet...'
      w1 = u.create_wallet
      expect(w1).not_to be_nil
      puts "Created new wallet with ID: #{w1.wallet_id}, default address: #{w1.default_address}"

      puts 'Importing wallet with balance...'
      data_string = ENV['WALLET_DATA']
      data_hash = JSON.parse(data_string)
      data = Coinbase::Wallet::Data.from_hash(data_hash)
      w2 = u.import_wallet(data)
      expect(w2).not_to be_nil
      puts "Imported wallet with ID: #{w2.wallet_id}, default address: #{w2.default_address}"

      puts 'Listing addresses...'
      addresses = w2.list_addresses
      expect(addresses.length).to be > 1
      puts "Listed addresses: #{addresses.map(&:to_s).join(', ')}"

      puts 'Fetching balances...'
      balances = w2.list_balances
      expect(balances.length).to be >= 1
      puts "Fetched balances: #{balances}"

      puts 'Transfering 1 Gwei from default address to second address...'
      a1 = addresses[0]
      a2 = addresses[1]
      t = a1.transfer(1, :gwei, a2).wait!
      expect(t.status).to eq(:complete)
      puts "Transferred 1 Gwei from #{a1} to #{a2}"

      puts 'Fetching updated balances...'
      first_balance = a1.list_balances
      second_balance = a2.list_balances
      expect(first_balance[:eth]).to be > BigDecimal('0')
      expect(second_balance[:eth]).to be > BigDecimal('0')
      puts "First address balances: #{first_balance}"
      puts "Second address balances: #{second_balance}"
    end
  end
end

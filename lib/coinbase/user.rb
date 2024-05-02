# frozen_string_literal: true

require_relative 'client'
require_relative 'wallet'

module Coinbase
  # A representation of a User. Users have Wallets, which can hold balances of Assets. Access the default User through
  # Coinbase#default_user.
  class User
    # Returns a new User object. Do not use this method directly. Instead, use Coinbase#default_user.
    # @param model [Coinbase::Client::User] the underlying User object
    def initialize(model)
      @model = model
    end

    # Returns the User ID.
    # @return [String] the User ID
    def user_id
      @model.id
    end

    # Creates a new Wallet belonging to the User.
    # @return [Coinbase::Wallet] the new Wallet
    def create_wallet
      create_wallet_request = {
        wallet: {
          # TODO: Don't hardcode this.
          network_id: 'base-sepolia'
        }
      }
      opts = { create_wallet_request: create_wallet_request }

      model = wallets_api.create_wallet(opts)

      Wallet.new(model)
    end

    # Imports a Wallet belonging to the User.
    # @param data [Coinbase::Wallet::Data] the Wallet data to import
    # @return [Coinbase::Wallet] the imported Wallet
    def import_wallet(data)
      model = wallets_api.get_wallet(data.wallet_id)
      address_count = addresses_api.list_addresses(model.id).total_count
      Wallet.new(model, seed: data.seed, address_count: address_count)
    end

    # Lists the IDs of the Wallets belonging to the User.
    # @return [Array<String>] the IDs of the Wallets belonging to the User
    def list_wallet_ids
      wallets = wallets_api.list_wallets
      wallets.data.map(&:id)
    end

    # Saves a wallet to local file system. Wallet saved this way can be re-instantiated with load() function,
    # provided the backup_file is available.
    def save(wallet, encrypt_flag = false)
      existing_seeds_in_store = existing_seeds
      data = wallet.export
      seed_to_store = data.seed
      auth_tag = ''
      iv = ''
      if encrypt_flag
        shared_secret = store_encryption_key
        cipher = OpenSSL::Cipher::AES256.new(:GCM).encrypt
        cipher.key = OpenSSL::Digest.digest('SHA256', shared_secret)
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.auth_data = ''
        encrypted_data = cipher.update(data.seed) + cipher.final
        auth_tag = cipher.auth_tag.unpack1('H*')
        iv = iv.unpack1('H*')
        seed_to_store = encrypted_data.unpack1('H*')
      end

      existing_seeds_in_store[data.wallet_id] = {
        seed: seed_to_store,
        encrypted: encrypt_flag,
        auth_tag: auth_tag,
        iv: iv,
      }

      File.open(Coinbase.configuration.backup_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(existing_seeds_in_store))
      end
    end

    # Loads all wallets belonging to the User with backup persisted to the local file system.
    # @return [Map<String>Coinbase::Wallet] the map of wallet_ids to the wallets.
    def load
      existing_seeds_in_store = existing_seeds
      wallets = {}
      existing_seeds_in_store.each do |wallet_id, seed_data|
        seed = seed_data['seed']
        if seed_data['encrypted']
          shared_secret = store_encryption_key
          cipher = OpenSSL::Cipher::AES256.new(:GCM).decrypt
          cipher.key = OpenSSL::Digest.digest('SHA256', shared_secret)
          iv = [seed_data['iv']].pack('H*')
          cipher.iv = iv
          auth_tag = [seed_data['auth_tag']].pack('H*')
          cipher.auth_tag = auth_tag
          cipher.auth_data = ''
          hex_decoded_data = [seed_data['seed']].pack('H*')
          seed = cipher.update(hex_decoded_data) + cipher.final
        end

        data = Coinbase::Wallet::Data.new(wallet_id: wallet_id, seed: seed)
        wallets[wallet_id] = import_wallet(data)
      end
      wallets
    end

    private

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end

    def wallets_api
      @wallets_api ||= Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
    end

    def existing_seeds
      existing_seed_data = '{}'
      file_path = Coinbase.configuration.backup_file_path
      existing_seed_data = File.read(file_path) if File.exist?(file_path)
      JSON.parse(existing_seed_data)
    end

    def store_encryption_key
      pk = OpenSSL::PKey.read(Coinbase.configuration.api_key_private_key)
      public_key = pk.public_key # use own public key to generate the shared secret.
      pk.dh_compute_key(public_key)
    end

  end
end

# frozen_string_literal: true

require 'digest'
require 'jimson'
require 'json'
require 'money-tree'
require 'securerandom'

module Coinbase
  # A representation of a Wallet. Wallets come with a single default Address, but can expand to have a set of Addresses,
  # each of which can hold a balance of one or more Assets. Wallets can create new Addresses, list their addresses,
  # list their balances, and transfer Assets to other Addresses. Wallets should be created through User#create_wallet or
  # User#import_wallet.
  class Wallet
    attr_reader :addresses, :model

    # The maximum number of addresses in a Wallet.
    MAX_ADDRESSES = 20

    class << self
      # Imports a Wallet from previously exported wallet data.
      # @param data [Coinbase::Wallet::Data] the Wallet data to import
      # @return [Coinbase::Wallet] the imported Wallet
      def import(data)
        raise ArgumentError, 'data must be a Coinbase::Wallet::Data object' unless data.is_a?(Data)

        model = Coinbase.call_api do
          wallets_api.get_wallet(data.wallet_id)
        end

        address_list = Coinbase.call_api do
          addresses_api.list_addresses(model.id, { limit: MAX_ADDRESSES })
        end

        new(model, seed: data.seed, address_models: address_list.data)
      end

      # Creates a new Wallet on the specified Network and generate a default address for it.
      # @param network_id [String] (Optional) the ID of the blockchain network. Defaults to 'base-sepolia'.
      # @return [Coinbase::Wallet] the new Wallet
      def create(network_id: 'base-sepolia')
        model = Coinbase.call_api do
          wallets_api.create_wallet(
            create_wallet_request: {
              wallet: {
                network_id: network_id
              }
            }
          )
        end

        wallet = new(model)

        wallet.create_address

        wallet
      end

      private

      # TODO: Memoize these objects in a thread-safe way at the top-level.
      def addresses_api
        Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
      end

      def wallets_api
        Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
      end
    end

    # Returns a new Wallet object. Do not use this method directly. Instead, use User#create_wallet or
    # User#import_wallet.
    # @param model [Coinbase::Client::Wallet] The underlying Wallet object
    # @param seed [String] (Optional) The seed to use for the Wallet. Expects a 32-byte hexadecimal with no 0x prefix.
    #   If nil, a new seed will be generated. If the empty string, no seed is generated, and the Wallet will be
    #   instantiated without a seed and its corresponding private keys.
    # @param address_models [Array<Coinbase::Client::Address>] (Optional) The models of the addresses already registered
    #   with the Wallet. If not provided, the Wallet will derive the first default address.
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    def initialize(model, seed: nil, address_models: [])
      validate_seed_and_address_models(seed, address_models)

      @model = model
      @master = master_node(seed)
      @addresses = []
      @private_key_index = 0

      derive_addresses(address_models)
    end

    # Returns the Wallet ID.
    # @return [String] The Wallet ID
    def id
      @model.id
    end

    # Returns the Network ID of the Wallet.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
    end

    # Sets the seed of the Wallet. This seed is used to derive keys and sign transactions.
    # @param seed [String] The seed to set. Expects a 32-byte hexadecimal with no 0x prefix.
    def seed=(seed)
      raise ArgumentError, 'Seed must be 32 bytes' if seed.length != 64
      raise 'Seed is already set' unless @master.nil?
      raise 'Cannot set seed for Wallet with non-zero private key index' if @private_key_index.positive?

      @master = MoneyTree::Master.new(seed_hex: seed)

      @addresses.each do
        key = derive_key
        a = address(key.address.to_s)
        raise "Seed does not match wallet; cannot find address #{key.address}" if a.nil?

        a.key = key
      end
    end

    # Creates a new Address in the Wallet.
    # @return [Address] The new Address
    def create_address
      key = derive_key
      attestation = create_attestation(key)
      public_key = key.public_key.compressed.unpack1('H*')

      opts = {
        create_address_request: {
          public_key: public_key,
          attestation: attestation
        }
      }
      address_model = Coinbase.call_api do
        addresses_api.create_address(id, opts)
      end

      # Auto-reload wallet to set default address on first address creation.
      reload if addresses.empty?

      cache_address(address_model, key)
    end

    # Returns the default address of the Wallet.
    # @return [Address] The default address
    def default_address
      address(@model.default_address&.address_id)
    end

    # Returns the Address with the given ID.
    # @param address_id [String] The ID of the Address to retrieve
    # @return [Address] The Address
    def address(address_id)
      @addresses.find { |address| address.id == address_id }
    end

    # Returns the list of balances of this Wallet. Balances are aggregated across all Addresses in the Wallet.
    # @return [BalanceMap] The list of balances. The key is the Asset ID, and the value is the balance.
    def balances
      response = Coinbase.call_api do
        wallets_api.list_wallet_balances(id)
      end

      Coinbase::BalanceMap.from_balances(response.data)
    end

    # Returns the balance of the provided Asset. Balances are aggregated across all Addresses in the Wallet.
    # @param asset_id [Symbol] The ID of the Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def balance(asset_id)
      response = Coinbase.call_api do
        wallets_api.get_wallet_balance(id, Coinbase::Asset.primary_denomination(asset_id).to_s)
      end

      return BigDecimal('0') if response.nil?

      Coinbase::Balance.from_model_and_asset_id(response, asset_id).amount
    end

    # Transfers the given amount of the given Asset to the given address. Only same-Network Transfers are supported.
    # Currently only the default_address is used to source the Transfer.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @return [Transfer] The hash of the Transfer transaction.
    def transfer(amount, asset_id, destination)
      if destination.is_a?(Wallet)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.default_address.id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != network_id

        destination = destination.id
      end

      default_address.transfer(amount, asset_id, destination)
    end

    # Exports the Wallet's data to a Data object.
    # @return [Data] The Wallet data
    def export
      raise 'Cannot export Wallet without loaded seed' if @master.nil?

      Data.new(wallet_id: id, seed: @master.seed_hex)
    end

    # Requests funds from the faucet for the Wallet's default address and returns the faucet transaction.
    # This is only supported on testnet networks.
    # @return [Coinbase::FaucetTransaction] The successful faucet transaction
    # @raise [Coinbase::FaucetLimitReachedError] If the faucet limit has been reached for the address or user.
    # @raise [Coinbase::Client::ApiError] If an unexpected error occurs while requesting faucet funds.
    def faucet
      Coinbase.call_api do
        Coinbase::FaucetTransaction.new(addresses_api.request_faucet_funds(id, default_address.id))
      end
    end

    # Returns whether the Wallet has a seed with which to derive keys and sign transactions.
    # @return [Boolean] Whether the Wallet has a seed with which to derive keys and sign transactions.
    def can_sign?
      !@master.nil?
    end

    # Returns a String representation of the Wallet.
    # @return [String] a String representation of the Wallet
    def to_s
      "Coinbase::Wallet{wallet_id: '#{id}', network_id: '#{network_id}', " \
        "default_address: '#{@model.default_address&.address_id}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Wallet
    def inspect
      to_s
    end

    # The data required to recreate a Wallet.
    class Data
      attr_reader :wallet_id, :seed

      # Returns a new Data object.
      # @param wallet_id [String] The ID of the Wallet
      # @param seed [String] The seed of the Wallet
      def initialize(wallet_id:, seed:)
        @wallet_id = wallet_id
        @seed = seed
      end

      # Converts the Data object to a Hash.
      # @return [Hash] The Hash representation of the Data object
      def to_hash
        { wallet_id: wallet_id, seed: seed }
      end

      # Creates a Data object from the given Hash.
      # @param data [Hash] The Hash to create the Data object from
      # @return [Data] The new Data object
      def self.from_hash(data)
        Data.new(wallet_id: data['wallet_id'], seed: data['seed'])
      end
    end

    private

    # Reloads the Wallet with the latest data.
    def reload
      @model = Coinbase.call_api do
        wallets_api.get_wallet(id)
      end
    end

    def master_node(seed)
      return MoneyTree::Master.new if seed.nil?
      return nil if seed.empty?

      MoneyTree::Master.new(seed_hex: seed)
    end

    def address_path_prefix
      # TODO: Add support for other networks.
      @address_path_prefix ||= case network_id.to_s.split('_').first
                               when 'base'
                                 "m/44'/60'/0'/0"
                               else
                                 raise ArgumentError, "Unsupported network ID: #{network_id}"
                               end
    end

    # Derives the registered Addresses in the Wallet.
    # @param address_models [Array<Coinbase::Client::Address>] The models of the addresses already registered with the
    #   Wallet
    def derive_addresses(address_models)
      return unless address_models.any?

      # Create a map tracking which addresses are already registered with the Wallet.
      address_map = build_address_map(address_models)

      address_models.each do |address_model|
        # Derive the addresses using the provided models.
        derive_address(address_map, address_model)
      end
    end

    # Derives an already registered Address in the Wallet.
    # @param address_map [Hash<String, Boolean>] The map of registered Address IDs
    # @param address_model [Coinbase::Client::Address] The Address model
    # @return [Address] The new Address
    def derive_address(address_map, address_model)
      key = @master.nil? ? nil : derive_key

      unless key.nil?
        address_from_key = key.address.to_s
        raise 'Invalid address' if address_map[address_from_key].nil?
      end

      cache_address(address_model, key)
    end

    # Derives a key for an already registered Address in the Wallet.
    # @return [Eth::Key] The new key
    def derive_key
      raise 'Cannot derive key for Wallet without seed loaded' if @master.nil?

      path = "#{address_path_prefix}/#{@private_key_index}"
      private_key = @master.node_for_path(path).private_key.to_hex
      @private_key_index += 1
      Eth::Key.new(priv: private_key)
    end

    # Caches an Address on the client-side and increments the address index.
    # @param address_model [Coinbase::Client::Address] The Address model
    # @param key [Eth::Key] The private key of the Address
    # @return [Address] The new Address
    def cache_address(address_model, key)
      address = Address.new(address_model, key)
      @addresses << address
      address
    end

    # Builds a Hash of the registered Addresses.
    # @param address_models [Array<Coinbase::Client::Address>] The models of the addresses already registered with the
    #   Wallet
    # @return [Hash<String, Boolean>] The Hash of registered Addresses
    def build_address_map(address_models)
      address_map = {}
      address_models.each do |address_model|
        address_map[address_model.address_id] = true
      end

      address_map
    end

    # Creates an attestation for the Address currently being created.
    # @param key [Eth::Key] The private key of the Address
    # @return [String] The attestation
    def create_attestation(key)
      public_key = key.public_key.compressed.unpack1('H*')
      payload = {
        wallet_id: id,
        public_key: public_key
      }.to_json
      hashed_payload = Digest::SHA256.digest(payload)
      signature = key.sign(hashed_payload)

      # The secp256k1 library serializes the signature as R, S, V.
      # The server expects the signature as V, R, S in the format:
      # <(byte of 27+public key solution)+4 if compressed >< padded bytes for signature R><padded bytes for signature S>
      # Ruby gem does not add 4 to the recovery byte, so we need to add it here.
      # Take the last byte (V) and add 4 to it to show signature is compressed.
      signature_bytes = [signature].pack('H*').unpack('C*')
      last_byte = signature_bytes.last
      compressed_last_byte = last_byte + 4
      new_signature_bytes = [compressed_last_byte] + signature_bytes[0..-2]
      new_signature_bytes.pack('C*').unpack1('H*')
    end

    # Validates the seed and address models passed to the constructor.
    # @param seed [String] The seed to use for the Wallet
    # @param address_models [Array<Coinbase::Client::Address>] The models of the addresses already registered with the
    #   Wallet
    def validate_seed_and_address_models(seed, address_models)
      raise ArgumentError, 'Seed must be 32 bytes' if !seed.nil? && !seed.empty? && seed.length != 64

      raise ArgumentError, 'Seed must be present if address_models are provided' if seed.nil? && address_models.any?

      return unless !seed.nil? && seed.empty? && address_models.empty?

      raise ArgumentError, 'Seed must be empty if address_models are not provided'
    end

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end

    def wallets_api
      @wallets_api ||= Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
    end
  end
end

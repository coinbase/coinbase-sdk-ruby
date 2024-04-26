# frozen_string_literal: true

require 'digest'
require 'jimson'
require 'json'
require 'money-tree'
require 'securerandom'

module Coinbase
  # A representation of a Wallet. Wallets come with a single default Address, but can expand to have a set of Addresses,
  # each of which can hold a balance of one or more Assets. Wallets can create new Addresses, list their addresses,
  # list their balances, and transfer Assets to other Addresses. Wallets should be created through User#create_wallet.
  class Wallet
    # Returns a new Wallet object. Do not use this method directly. Instead, use User#create_wallet or
    # User#import_wallet.
    # @param model [Coinbase::Client::Wallet] The underlying Wallet object
    # @param wallets_api [Coinbase::Client::WalletsApi] the Wallets API to use
    # @param addresses_api [Coinbase::Client::AddressesApi] the Addresses API to use
    # @param seed [String] (Optional) The seed to use for the Wallet. Expects a 32-byte hexadecimal with no 0x prefix.
    #   If not provided, a new seed will be generated.
    # @param address_count [Integer] (Optional) The number of addresses already registered for the Wallet.
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    def initialize(model, wallets_api, addresses_api, seed: nil, address_count: 0,
                   client: Jimson::Client.new(Coinbase.base_sepolia_rpc_url))
      raise ArgumentError, 'Seed must be 32 bytes' if !seed.nil? && seed.length != 64

      @model = model
      @wallets_api = wallets_api
      @addresses_api = addresses_api

      @master = seed.nil? ? MoneyTree::Master.new : MoneyTree::Master.new(seed_hex: seed)

      # TODO: Make Network an argument to the constructor.
      @network_id = :base_sepolia
      @addresses = []

      # TODO: Adjust derivation path prefix based on network protocol.
      @address_path_prefix = "m/44'/60'/0'/0"
      @address_index = 0

      @client = client

      if address_count.positive?
        address_count.times { derive_address }
      else
        create_address
        # Update the model to reflect the new default address.
        update_model
      end
    end

    # Returns the Wallet ID.
    # @return [String] The Wallet ID
    def wallet_id
      @model.id
    end

    # Returns the Network ID of the Wallet.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
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
      address_model = @addresses_api.create_address(wallet_id, opts)

      cache_address(address_model, key, @client)
    end

    # Returns the default address of the Wallet.
    # @return [Address] The default address
    def default_address
      @addresses.find { |address| address.address_id == @model.default_address.address_id }
    end

    # Returns the Address with the given ID.
    # @param address_id [String] The ID of the Address to retrieve
    # @return [Address] The Address
    def get_address(address_id)
      @addresses.find { |address| address.address_id == address_id }
    end

    # Returns the list of Addresses in the Wallet.
    # @return [Array<Address>] The list of Addresses
    def list_addresses
      @addresses
    end

    # Returns the list of balances of this Wallet. Balances are aggregated across all Addresses in the Wallet.
    # @return [BalanceMap] The list of balances. The key is the Asset ID, and the value is the balance.
    def list_balances
      response = @wallets_api.list_wallet_balances(wallet_id)
      Coinbase.to_balance_map(response)
    end

    # Returns the balance of the provided Asset. Balances are aggregated across all Addresses in the Wallet.
    # @param asset_id [Symbol] The ID of the Asset to retrieve the balance for
    # @return [BigDecimal] The balance of the Asset
    def get_balance(asset_id)
      normalized_asset_id = if %i[wei gwei].include?(asset_id)
                              :eth
                            else
                              asset_id
                            end

      response = @wallets_api.get_wallet_balance(wallet_id, normalized_asset_id.to_s)

      return BigDecimal('0') if response.nil?

      amount = BigDecimal(response.amount)

      case asset_id
      when :eth
        amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s)
      when :gwei
        amount / BigDecimal(Coinbase::GWEI_PER_ETHER.to_s)
      else
        amount
      end
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
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.default_address.address_id
      elsif destination.is_a?(Address)
        raise ArgumentError, 'Transfer must be on the same Network' if destination.network_id != @network_id

        destination = destination.address_id
      end

      default_address.transfer(amount, asset_id, destination)
    end

    # Exports the Wallet's data to a Data object.
    # @return [Data] The Wallet data
    def export
      Data.new(wallet_id, @master.seed_hex)
    end

    # The data required to recreate a Wallet.
    class Data
      attr_reader :wallet_id, :seed

      # Returns a new Data object.
      # @param wallet_id [String] The ID of the Wallet
      # @param seed [String] The seed of the Wallet
      def initialize(wallet_id, seed)
        @wallet_id = wallet_id
        @seed = seed
      end
    end

    private

    # Derives an already registered Address in the Wallet.
    # @return [Address] The new Address
    def derive_address
      key = derive_key

      address_id = key.address.to_s
      address_model = @addresses_api.get_address(wallet_id, address_id)

      cache_address(address_model, key, @client)
    end

    # Derives a key for an already registered Address in the Wallet.
    # @return [Eth::Key] The new key
    def derive_key
      path = "#{@address_path_prefix}/#{@address_index}"
      private_key = @master.node_for_path(path).private_key.to_hex
      Eth::Key.new(priv: private_key)
    end

    # Caches an Address on the client-side and increments the address index.
    # @param address_model [Coinbase::Client::Address] The Address model
    # @param key [Eth::Key] The private key of the Address
    # @param client [Jimson::Client] The JSON RPC client to use for interacting with the Network
    # @return [Address] The new Address
    def cache_address(address_model, key, client)
      address = Address.new(address_model, @addresses_api, key, client: client)
      @addresses << address
      @address_index += 1
      address
    end

    # Creates an attestation for the Address currently being created.
    # @param key [Eth::Key] The private key of the Address
    # @return [String] The attestation
    def create_attestation(key)
      public_key = key.public_key.compressed.unpack1('H*')
      payload = {
        wallet_id: wallet_id,
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

    # Updates the Wallet model with the latest data.
    def update_model
      @model = @wallets_api.get_wallet(wallet_id)
    end
  end
end

# frozen_string_literal: true

require 'digest'
require 'json'
require 'money-tree'
require 'securerandom'

require_relative 'wallet/data'

module Coinbase
  # A representation of a Wallet. Wallets come with a single default Address, but can expand to have a set of Addresses,
  # each of which can hold a balance of one or more Assets. Wallets can create new Addresses, list their addresses,
  # list their balances, and transfer Assets to other Addresses.
  class Wallet
    extend Forwardable

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

        new(model, seed: data.seed)
      end

      # Enumerates the wallets for the requesting user.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted to an array, etc...
      # @return [Enumerable<Coinbase::Wallet>] Enumerator that returns wallets
      def list
        Coinbase::Pagination.enumerate(method(:fetch_wallets_page)) do |wallet|
          Coinbase::Wallet.new(wallet, seed: '')
        end
      end

      # Fetches a Wallet by its ID.
      # The returned wallet can be immediately used for signing operations if backed by a server signer.
      # If the wallet is not backed by a server signer, the wallet's seed will need to be set before
      # it can be used for signing operations.
      # @param wallet_id [String] The ID of the Wallet to fetch
      # @return [Coinbase::Wallet] The fetched Wallet
      def fetch(wallet_id)
        model = Coinbase.call_api do
          wallets_api.get_wallet(wallet_id)
        end

        new(model, seed: '')
      end

      # Creates a new Wallet on the specified Network and generate a default address for it.
      # @param network [Coinbase::Network, Symbol] (Optional) The network object or ID to create the
      #   Wallet on. When omitted this uses the SDK configured default network.
      # @param interval_seconds [Integer] The interval at which to poll the CDPService for the Wallet to
      # have an active seed, if using a ServerSigner, in seconds
      # @param timeout_seconds [Integer] The maximum amount of time to wait for the ServerSigner to
      # create a seed for the Wallet, in seconds
      # @return [Coinbase::Wallet] the new Wallet
      def create(network: Coinbase.default_network, interval_seconds: 0.2, timeout_seconds: 20)
        model = Coinbase.call_api do
          wallets_api.create_wallet(
            create_wallet_request: {
              wallet: {
                network_id: Coinbase.normalize_network(network),
                use_server_signer: Coinbase.use_server_signer?
              }
            }
          )
        end

        wallet = new(model)

        # When used with a ServerSigner, the Signer must first register
        # with the Wallet before addresses can be created.
        wait_for_signer(wallet.id, interval_seconds, timeout_seconds) if Coinbase.use_server_signer?

        wallet.create_address
        wallet
      end

      private

      # Wait_for_signer waits until the ServerSigner has created a seed for the Wallet.
      # Timeout::Error if the ServerSigner takes longer than the given timeout to create the seed.
      # @param wallet_id [string] The ID of the Wallet that is awaiting seed creation.
      # @param interval_seconds [Integer] The interval at which to poll the CDPService, in seconds
      # @param timeout_seconds [Integer] The maximum amount of time to wait for the Signer to create a seed, in seconds
      # @return [Wallet] The completed Wallet object that is ready to create addresses.
      def wait_for_signer(wallet_id, interval_seconds, timeout_seconds)
        start_time = Time.now

        loop do
          model = Coinbase.call_api do
            wallets_api.get_wallet(wallet_id)
          end

          return self if model.server_signer_status == ServerSigner::Status::ACTIVE

          if Time.now - start_time > timeout_seconds
            raise Timeout::Error, 'Wallet creation timed out. Check status of your Server-Signer'
          end

          self.sleep interval_seconds
        end

        self
      end

      def addresses_api
        Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
      end

      def wallets_api
        Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
      end

      def fetch_wallets_page(page)
        wallets_api.list_wallets({ limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

    # Returns a new Wallet object. Do not use this method directly. Instead use Coinbase::Wallet.create.
    # @param model [Coinbase::Client::Wallet] The underlying Wallet object
    # @param seed [String] (Optional) The seed to use for the Wallet. Expects a 32-byte hexadecimal with no 0x prefix.
    #   If nil, a new seed will be generated. If the empty string, no seed is generated, and the Wallet will be
    #   instantiated without a seed and its corresponding private keys.
    #   with the Wallet. If not provided, the Wallet will derive the first default address.
    def initialize(model, seed: nil)
      raise ArgumentError, 'model must be a Wallet' unless model.is_a?(Coinbase::Client::Wallet)

      @model = model

      return if Coinbase.use_server_signer?

      @master = master_node(seed)
    end

    # @!method transfer
    # Transfers the amount of the Asset from the default address to the specified destination.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send
    # @param asset_id [Symbol] The ID of the Asset to send
    # @param destination [Wallet | Address | String] The destination of the transfer.
    #  If a Wallet, sends to the Wallet's default address.
    #  If a String, interprets it as the address ID.
    # @param gasless [Boolean] Whether the transfer should be gasless. Defaults to false.
    # @return [Coinbase::Transfer] The Transfer object.
    # (see Coinbase::Address::WalletAddress#transfer)

    # @!method trade
    # Trades the specified amount from one asset to another using the default address.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param from_asset_id [Symbol] The ID of the Asset to trade from.
    # @param to_asset_id [Symbol] The ID of the Asset to trade to.
    #  default address. If a String, interprets it as the address ID.
    # @return [Coinbase::Trade] The Trade object.

    # @!method faucet
    # @param asset_id [Symbol] The ID of the Asset to transfer to the wallet.
    # Requests funds from the faucet for the Wallet's default address and returns the faucet transaction.
    # This is only supported on testnet networks.
    # @return [Coinbase::FaucetTransaction] The successful faucet transaction
    # @raise [Coinbase::FaucetLimitReachedError] If the faucet limit has been reached for the address or user.
    # @raise [Coinbase::Client::ApiError] If an unexpected error occurs while requesting faucet funds.

    # @!method stake
    # Stakes the given amount of the given Asset for the default address.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to stake.
    # @param asset_id [Symbol] The ID of the Asset to stake.
    # @param mode [Symbol] (Optional) The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the staking operation.
    # @return [Coinbase::StakingOperation] The stake operation

    # @!method unstake
    # Unstakes the given amount of the given Asset on the default address.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to unstake.
    # @param asset_id [Symbol] The ID of the Asset to unstake.
    # @param mode [Symbol] (Optional) The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the unstaking operation.
    # @return [Coinbase::StakingOperation] The unstake operation

    # @!method claim_stake
    # Claims stake of the given amount of the given Asset for the default address.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to claim_stake.
    # @param asset_id [Symbol] The ID of the Asset to claim_stake.
    # @param mode [Symbol] (Optional) The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the unstaking operation.
    # @return [Coinbase::StakingOperation] The claim_stake operation

    # @!method staking_balances
    # Retrieves the balances used for staking for the supplied asset for the default address.
    # @param asset_id [Symbol] The asset to retrieve staking balances for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [Hash] The staking balances
    # @return [BigDecimal] :stakeable_balance The amount of the asset that can be staked
    # @return [BigDecimal] :unstakeable_balance The amount of the asset that is currently staked and cannot be unstaked
    # @return [BigDecimal] :claimable_balance The amount of the asset that can be claimed

    # @!method stakeable_balance
    # Retrieves the stakeable balance of the supplied asset for the default address.
    # @param asset_id [Symbol] The asset to retrieve the stakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The stakeable balance

    # @!method unstakeable_balance
    # Retrieves the unstakeable balance for the supplied asset.
    # Currently only the default_address is used to source the unstakeable balance.
    # @param asset_id [Symbol] The asset to retrieve the unstakeable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The unstakeable balance

    # @!method claimable_balance
    # Retrieves the claimable balance for the supplied asset.
    # Currently only the default_address is used to source the claimable balance.
    # @param asset_id [Symbol] The asset to retrieve the claimable balance for
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] Additional options for the staking operation
    # @return [BigDecimal] The claimable balance

    # @!method sign_payload
    # Signs the given unsigned payload.
    # @param unsigned_payload [String] The hex-encoded hashed unsigned payload for the Address to sign.
    # @return [Coinbase::PayloadSignature] The payload signature

    # @!method invoke_contract
    # Invokes a contract with the given ABI, method, and arguments.
    # @param abi [Array<Hash>] The ABI of the contract

    # @!method deploy_token
    # Deploys a new ERC20 token contract with the given name, symbol, and total supply.
    # @param name [String] The name of the token.
    # @param symbol [String] The symbol of the token.
    # @param total_supply [Integer, BigDecimal] The total supply of the token, denominated in
    # whole units.
    # @return [Coinbase::SmartContract] The deployed token contract.
    # @raise [AddressCannotSignError] if the Address does not have a private key backing it.

    def_delegators :default_address, :transfer, :trade, :faucet, :stake, :unstake, :claim_stake, :staking_balances,
                   :stakeable_balance, :unstakeable_balance, :claimable_balance, :sign_payload, :invoke_contract,
                   :deploy_token

    # Returns the addresses belonging to the Wallet.
    # @return [Array<Coinbase::WalletAddress>] The addresses belonging to the Wallet
    def addresses
      return @addresses unless @addresses.nil?

      set_addresses
    end

    # Returns the Wallet ID.
    # @return [String] The Wallet ID
    def id
      @model.id
    end

    # Returns the Network of the Wallet.
    # @return [Coinbase::Network] The Network of the Wallet
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the ServerSigner Status of the Wallet.
    # @return [Symbol] The ServerSigner Status
    def server_signer_status
      Coinbase.to_sym(@model.server_signer_status)
    end

    # Sets the seed of the Wallet. This seed is used to derive keys and sign transactions.
    # @param seed [String] The seed to set. Expects a 32-byte hexadecimal with no 0x prefix.
    def seed=(seed)
      raise ArgumentError, 'Seed must not be empty' if seed.nil? || seed.empty?
      raise StandardError, 'Seed is already set' unless @master.nil?

      @master = master_node(seed)

      # If the addresses are not loaded the keys will be set on them whenever they are loaded.
      return if @addresses.nil?

      # If addresses are already loaded, set the keys on each address.
      addresses.each_with_index.each do |address, index|
        key = derive_key(index)

        # If we derive a key the derived address must match the address from the API.
        raise StandardError, 'Seed does not match wallet' unless address.id == key.address.to_s

        address.key = key
      end
    end

    # Creates a new Address in the Wallet.
    # @return [Address] The new Address
    def create_address
      req = {}

      # Ensure that the address cache is set before creating a new address.
      # This ensures that for a server signer, the addresses have been loaded and we
      # can create a new address and add it to a cache.
      set_addresses if @addresses.nil?

      unless Coinbase.use_server_signer?
        # The index for the next address is the number of addresses already registered.
        private_key_index = addresses.count

        key = derive_key(private_key_index)

        req = {
          public_key: key.public_key.compressed.unpack1('H*'),
          attestation: create_attestation(key),
          address_index: private_key_index
        }
      end

      address_model = Coinbase.call_api do
        addresses_api.create_address(id, { create_address_request: req })
      end

      # Default address can be nil because either this is the first address being
      # created for this wallet or the addresses cache has not yet been loaded.

      # If the default address is nil, we must reload the wallet model after creating
      # the address, in order for the default address to be set.
      reload if default_address.nil?

      # The addreses cache is already created, so we can add the new address to the cache.
      address = WalletAddress.new(address_model, key)
      @addresses << address
      address
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
      addresses.find { |address| address.id == address_id }
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

    # Exports the Wallet's data to a Data object.
    # @return [Coinbase::Wallet::Data] The Wallet data
    def export
      # TODO: Improve this check by relying on the backend data to decide whether a wallet is server-signer backed.
      raise 'Cannot export data for Server-Signer backed Wallet' if Coinbase.use_server_signer?

      raise 'Cannot export Wallet without loaded seed' if @master.nil?

      Data.new(wallet_id: id, seed: @master.seed_hex)
    end

    # Returns whether the Wallet has a seed with which to derive keys and sign transactions.
    # @return [Boolean] Whether the Wallet has a seed with which to derive keys and sign transactions.
    def can_sign?
      !@master.nil?
    end

    # Saves the seed of the Wallet to the given file. Wallets whose seeds are saved this way can be
    # rehydrated using load_seed. A single file can be used for multiple Wallet seeds.
    # This is an insecure method of storing Wallet seeds and should only be used for development purposes.
    #
    # @param file_path [String] The path of the file to save the seed to
    # @param encrypt [bool] (Optional) Whether the seed information persisted to the local file system should be
    # encrypted or not. Data is unencrypted by default.
    # @return [String] A string indicating the success of the operation
    def save_seed!(file_path, encrypt: false)
      raise 'Wallet does not have seed loaded' if @master.nil?

      existing_seeds_in_store = existing_seeds(file_path)

      seed_to_store = @master.seed_hex
      auth_tag = ''
      iv = ''
      if encrypt
        cipher = OpenSSL::Cipher.new('aes-256-gcm').encrypt
        cipher.key = OpenSSL::Digest.digest('SHA256', encryption_key)
        iv = cipher.random_iv
        cipher.iv = iv
        cipher.auth_data = ''
        encrypted_data = cipher.update(@master.seed_hex) + cipher.final
        auth_tag = cipher.auth_tag.unpack1('H*')
        iv = iv.unpack1('H*')
        seed_to_store = encrypted_data.unpack1('H*')
      end

      existing_seeds_in_store[id] = {
        seed: seed_to_store,
        encrypted: encrypt,
        auth_tag: auth_tag,
        iv: iv
      }

      File.write(file_path, JSON.pretty_generate(existing_seeds_in_store))

      "Successfully saved seed for wallet #{id} to #{file_path}."
    end

    # Loads the seed of the Wallet from the given file.
    # @param file_path [String] The path of the file to load the seed from
    # @return [String] A string indicating the success of the operation
    def load_seed(file_path)
      raise 'Wallet already has seed loaded' unless @master.nil?

      existing_seeds_in_store = existing_seeds(file_path)

      raise ArgumentError, "File #{file_path} does not contain seed data" if existing_seeds_in_store == {}

      if existing_seeds_in_store[id].nil?
        raise ArgumentError, "File #{file_path} does not contain seed data for wallet #{id}"
      end

      seed_data = existing_seeds_in_store[id]
      local_seed = seed_data['seed']

      raise ArgumentError, 'Seed data is malformed' if local_seed.nil? || local_seed == ''

      if seed_data['encrypted']
        raise ArgumentError, 'Encrypted seed data is malformed' if seed_data['iv'] == '' ||
                                                                   seed_data['auth_tag'] == ''

        cipher = OpenSSL::Cipher.new('aes-256-gcm').decrypt
        cipher.key = OpenSSL::Digest.digest('SHA256', encryption_key)
        iv = [seed_data['iv']].pack('H*')
        cipher.iv = iv
        auth_tag = [seed_data['auth_tag']].pack('H*')
        cipher.auth_tag = auth_tag
        cipher.auth_data = ''
        hex_decoded_data = [seed_data['seed']].pack('H*')
        local_seed = cipher.update(hex_decoded_data) + cipher.final
      end

      self.seed = local_seed

      "Successfully loaded seed for wallet #{id} from #{file_path}."
    end

    # Returns a String representation of the Wallet.
    # @return [String] a String representation of the Wallet
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: id,
        network_id: network.id,
        default_address: @model.default_address&.address_id
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Wallet
    def inspect
      to_s
    end

    private

    # Reloads the Wallet with the latest data.
    def reload
      @model = Coinbase.call_api do
        wallets_api.get_wallet(id)
      end
    end

    # Returns the master node for the given seed.
    def master_node(seed)
      return MoneyTree::Master.new if seed.nil?
      return nil if seed.empty?

      validate_seed(seed)

      MoneyTree::Master.new(seed_hex: seed)
    end

    def address_path_prefix
      if network.address_path_prefix.nil? || network.address_path_prefix.empty?
        raise ArgumentError, "Cannot create address for network #{network.id}"
      end

      network.address_path_prefix
    end

    # Derives a key for the given address index.
    # @return [Eth::Key] The new key
    def derive_key(index)
      raise 'Cannot derive key for Wallet without seed loaded' if @master.nil?

      path = "#{address_path_prefix}/#{index}"
      private_key = @master.node_for_path(path).private_key.to_hex

      Eth::Key.new(priv: private_key)
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
    # @raise [ArgumentError] If the seed is invalid
    def validate_seed(seed)
      raise ArgumentError, 'Seed must be 32 bytes' unless seed.length == 64
    end

    # Loads the Hash of Wallet seeds from the given file.
    # @param file_path [String] The path of the file to load the seed from
    # @return [Hash<String, Hash>] The Hash of from Wallet IDs to seed data
    def existing_seeds(file_path)
      existing_seed_data = '{}'
      existing_seed_data = File.read(file_path) if File.exist?(file_path)
      existing_seeds = JSON.parse(existing_seed_data)
      raise ArgumentError, "#{file_path} is malformed, must be a valid JSON object" unless existing_seeds.is_a?(Hash)

      existing_seeds
    end

    # Returns the shared secret to use for encrypting the seed.
    def encryption_key
      pk = OpenSSL::PKey.read(Coinbase.configuration.api_key_private_key)
      public_key = pk.public_key # use own public key to generate the shared secret.
      pk.dh_compute_key(public_key)
    end

    def build_wallet_address(address_model, index)
      # Return an unhydrated wallet address is no master seed is set.
      return WalletAddress.new(address_model, nil) if @master.nil?

      key = derive_key(index)

      raise StandardError, 'Seed does not match wallet' unless address_model.address_id == key.address.to_s

      WalletAddress.new(address_model, key)
    end

    def addresses_api
      @addresses_api ||= Coinbase::Client::AddressesApi.new(Coinbase.configuration.api_client)
    end

    def wallets_api
      @wallets_api ||= Coinbase::Client::WalletsApi.new(Coinbase.configuration.api_client)
    end

    def set_addresses
      address_list = Coinbase.call_api do
        addresses_api.list_addresses(@model.id, { limit: MAX_ADDRESSES })
      end

      @addresses = address_list.data.each_with_index.map do |address_model, index|
        build_wallet_address(address_model, index)
      end
    end
  end
end

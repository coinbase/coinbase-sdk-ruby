# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Transfer, which moves an amount of an Asset from
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Transfers should be created through Wallet#transfer or
  # Address#transfer.
  class Transfer
    class << self
      # Creates a new Transfer object.
      # @param address_id [String] The Address ID of the sending Address
      # @param amount [BigDecimal] The amount of the Asset to send
      # @param asset_id [Symbol] The Asset ID of the Asset to send
      # @param destination [Coinbase::Destination, Coinbase::Wallet, Coinbase::Address, String]
      #   The destination of the transfer.
      #   If the destination is a Wallet, it uses the default Address of the Wallet.
      #   If the destination is an Address, it uses the Address's ID.
      #   If the destination is a String, it uses it as the Address ID.
      # @param network [Coinbase::Network, Symbol] The Network or Network ID of the Asset
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @return [Transfer] The new pending Transfer object
      # @raise [Coinbase::ApiError] If the Transfer fails
      def create(address_id:, amount:, asset_id:, destination:, network:, wallet_id:, gasless: false)
        network = Coinbase::Network.from_id(network)
        asset = network.get_asset(asset_id)

        model = Coinbase.call_api do
          transfers_api.create_transfer(
            wallet_id,
            address_id,
            {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              asset_id: asset.primary_denomination.to_s,
              destination: Coinbase::Destination.new(destination, network: network).address_id,
              network_id: network.normalized_id,
              gasless: gasless
            }
          )
        end

        new(model)
      end

      # Enumerates the transfers for a given address belonging to a wallet.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted to an array, etc...
      # @return [Enumerable<Coinbase::Transfer>] Enumerator that returns transfers
      def list(wallet_id:, address_id:)
        Coinbase::Pagination.enumerate(
          ->(page) { fetch_page(wallet_id, address_id, page) }
        ) do |transfer|
          new(transfer)
        end
      end

      private

      def transfers_api
        Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
      end

      def fetch_page(wallet_id, address_id, page)
        transfers_api.list_transfers(wallet_id, address_id, { limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

    # Returns a new Transfer object. Do not use this method directly. Instead, use Wallet#transfer or
    # Address#transfer.
    # @param model [Coinbase::Client::Transfer] The underlying Transfer object
    def initialize(model)
      raise unless model.is_a?(Coinbase::Client::Transfer)

      @model = model
    end

    # Returns the Transfer ID.
    # @return [String] The Transfer ID
    def id
      @model.transfer_id
    end

    # Returns the Network of the Transfer.
    # @return [Coinbase::Network] The Network
    def network
      @network ||= Coinbase::Network.from_id(@model.network_id)
    end

    # Returns the Wallet ID of the Transfer.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Returns the From Address ID of the Transfer.
    # @return [String] The From Address ID
    def from_address_id
      @model.address_id
    end

    # Returns the Destination Address ID of the Transfer.
    # @return [String] The Destination Address ID
    def destination_address_id
      @model.destination
    end

    def asset
      @asset ||= Coinbase::Asset.from_model(@model.asset)
    end

    # Returns the Asset ID of the Transfer.
    # @return [Symbol] The Asset ID
    def asset_id
      @model.asset_id.to_sym
    end

    # Returns the amount of the asset for the Transfer.
    # @return [BigDecimal] The amount of the asset
    def amount
      BigDecimal(@model.amount) / BigDecimal(10).power(@model.asset.decimals)
    end

    # Signs the Transfer with the given key. This is required before broadcasting the Transfer.
    # @param key [Eth::Key] The key to sign the Transfer with
    # @raise [RuntimeError] If the key is not an Eth::Key
    # @return [Transfer] The Transfer object
    def sign(key)
      raise unless key.is_a?(Eth::Key)

      unless sponsored_send.nil?
        sponsored_send.sign(key)

        return
      end

      transaction.sign(key)

      self
    end

    # Returns the Transfer transaction.
    # @return [Coinbase::Transaction] The Transfer transaction
    def transaction
      @transaction ||= @model.transaction.nil? ? nil : Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the SponsoredSend of the Transfer, if the transfer is gasless.
    # @return [Coinbase::SponsoredSend] The SponsoredSend object
    def sponsored_send
      @sponsored_send ||= @model.sponsored_send.nil? ? nil : Coinbase::SponsoredSend.new(@model.sponsored_send)
    end

    # Returns the status of the Transfer.
    # @return [Symbol] The status
    def status
      send_tx_delegate.status
    end

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      send_tx_delegate.transaction_link
    end

    # Returns the Transaction Hash of the Transfer.
    # @return [String] The Transaction Hash
    def transaction_hash
      send_tx_delegate.transaction_hash
    end

    # Broadcasts the Transfer to the Network.
    # This raises an error if the Transfer is not signed.
    # @raise [RuntimeError] If the Transfer is not signed
    # @return [Transfer] The Transfer object
    def broadcast!
      raise TransactionNotSignedError unless send_tx_delegate.signed?

      @model = Coinbase.call_api do
        transfers_api.broadcast_transfer(
          wallet_id,
          from_address_id,
          id,
          { signed_payload: send_tx_delegate.signature }
        )
      end

      update_transaction(@model) unless @model.transaction.nil?
      update_sponsored_send(@model) unless @model.sponsored_send.nil?

      self
    end

    # Reload reloads the Transfer model with the latest version from the server side.
    # @return [Transfer] The most recent version of Transfer from the server.
    def reload
      @model = Coinbase.call_api do
        transfers_api.get_transfer(wallet_id, from_address_id, id)
      end

      update_transaction(@model) unless @model.transaction.nil?
      update_sponsored_send(@model) unless @model.sponsored_send.nil?

      self
    end

    # Waits until the Transfer is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Transfer takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Transfer to complete, in seconds
    # @return [Transfer] The completed Transfer object
    def wait!(interval_seconds = 0.2, timeout_seconds = 20)
      start_time = Time.now

      loop do
        reload

        return self if terminal_state?

        raise Timeout::Error, 'Transfer timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Transfer.
    # @return [String] a String representation of the Transfer
    def to_s
      "Coinbase::Transfer{transfer_id: '#{id}', network_id: '#{network.id}', " \
        "from_address_id: '#{from_address_id}', destination_address_id: '#{destination_address_id}', " \
        "asset_id: '#{asset_id}', amount: '#{amount}', transaction_link: '#{transaction_link}', " \
        "status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end

    private

    def terminal_state?
      send_tx_delegate.terminal_state?
    end

    def send_tx_delegate
      return sponsored_send unless sponsored_send.nil?

      transaction
    end

    def transfers_api
      @transfers_api ||= Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
    end

    def update_transaction(model)
      @transaction = Coinbase::Transaction.new(model.transaction)
    end

    def update_sponsored_send(model)
      @sponsored_send = Coinbase::SponsoredSend.new(model.sponsored_send)
    end
  end
end

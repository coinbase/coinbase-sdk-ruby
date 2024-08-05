# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'
require 'json'

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
      # @param network_id [Symbol] The Network ID of the Asset
      # @param wallet_id [String] The Wallet ID of the sending Wallet
      # @return [Transfer] The new pending Transfer object
      # @raise [Coinbase::ApiError] If the Transfer fails
      def create(address_id:, amount:, asset_id:, destination:, network_id:, wallet_id:)
        asset = Asset.fetch(network_id, asset_id)

        model = Coinbase.call_api do
          transfers_api.create_transfer(
            wallet_id,
            address_id,
            {
              amount: asset.to_atomic_amount(amount).to_i.to_s,
              asset_id: asset.primary_denomination.to_s,
              destination: Coinbase::Destination.new(destination, network_id: network_id).address_id,
              network_id: Coinbase.normalize_network(network_id)
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

    # Returns the Network ID of the Transfer.
    # @return [Symbol] The Network ID
    def network_id
      Coinbase.to_sym(@model.network_id)
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

    # Returns the link to the transaction on the blockchain explorer.
    # @return [String] The link to the transaction on the blockchain explorer
    def transaction_link
      # TODO: Parameterize this by Network.
      "https://sepolia.basescan.org/tx/#{transaction_hash}"
    end

    # Returns the Unsigned Payload of the Transfer.
    # @return [String] The Unsigned Payload
    def unsigned_payload
      transaction.unsigned_payload
    end

    # Returns the Signed Payload of the Transfer.
    # @return [String] The Signed Payload
    def signed_payload
      transaction.signed_payload
    end

    # Returns the Transfer transaction.
    # @return [Coinbase::Transaction] The Transfer transaction
    def transaction
      @transaction ||= Coinbase::Transaction.new(@model.transaction)
    end

    # Returns the Transaction Hash of the Transfer.
    # @return [String] The Transaction Hash
    def transaction_hash
      transaction.transaction_hash
    end

    # Returns the status of the Transfer.
    # @return [Symbol] The status
    def status
      transaction.status
    end

    # Broadcasts the Transfer to the Network.
    # This raises an error if the Transfer is not signed.
    # @raise [RuntimeError] If the Transfer is not signed
    # @return [Transfer] The Transfer object
    def broadcast!
      raise TransactionNotSignedError unless transaction.signed?

      @model = Coinbase.call_api do
        transfers_api.broadcast_transfer(
          wallet_id,
          from_address_id,
          id,
          { signed_payload: transaction.raw.hex }
        )
      end

      update_transaction(@model)

      self
    end

    # Reload reloads the Transfer model with the latest version from the server side.
    # @return [Transfer] The most recent version of Transfer from the server.
    def reload
      @model = Coinbase.call_api do
        transfers_api.get_transfer(wallet_id, from_address_id, id)
      end

      update_transaction(@model)

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

        return self if transaction.terminal_state?

        raise Timeout::Error, 'Transfer timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns a String representation of the Transfer.
    # @return [String] a String representation of the Transfer
    def to_s
      "Coinbase::Transfer{transfer_id: '#{id}', network_id: '#{network_id}', " \
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

    def transfers_api
      @transfers_api ||= Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
    end

    def update_transaction(model)
      @transaction = Coinbase::Transaction.new(model.transaction)
    end
  end
end

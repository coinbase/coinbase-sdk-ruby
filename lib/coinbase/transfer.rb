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
    # A representation of a Transfer status.
    module Status
      # The Transfer is awaiting being broadcast to the Network. At this point, transaction
      # hashes may not yet be assigned.
      PENDING = :pending

      # The Transfer has been broadcast to the Network. At this point, at least the transaction hash
      # should be assigned.
      BROADCAST = :broadcast

      # The Transfer is complete, and has confirmed on the Network.
      COMPLETE = :complete

      # The Transfer has failed for some reason.
      FAILED = :failed
    end

    # Returns a new Transfer object. Do not use this method directly. Instead, use Wallet#transfer or
    # Address#transfer.
    # @param model [Coinbase::Client::Transfer] The underlying Transfer object
    def initialize(model)
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

    # Returns the Asset ID of the Transfer.
    # @return [Symbol] The Asset ID
    def asset_id
      @model.asset_id.to_sym
    end

    # Returns the amount of the asset for the Transfer.
    # @return [BigDecimal] The amount of the asset
    def amount
      case asset_id
      when :eth
        BigDecimal(@model.amount) / BigDecimal(Coinbase::WEI_PER_ETHER.to_s)
      else
        BigDecimal(@model.amount)
      end
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
      @model.unsigned_payload
    end

    # Returns the Signed Payload of the Transfer.
    # @return [String] The Signed Payload
    def signed_payload
      @model.signed_payload
    end

    # Returns the Transaction Hash of the Transfer.
    # @return [String] The Transaction Hash
    def transaction_hash
      @model.transaction_hash
    end

    # Returns the underlying Transfer transaction, creating it if it has not been yet.
    # @return [Eth::Tx::Eip1559] The Transfer transaction
    def transaction
      return @transaction unless @transaction.nil?

      raw_payload = [unsigned_payload].pack('H*')
      parsed_payload = JSON.parse(raw_payload)

      params = {
        chain_id: parsed_payload['chainId'].to_i(16),
        nonce: parsed_payload['nonce'].to_i(16),
        priority_fee: parsed_payload['maxPriorityFeePerGas'].to_i(16),
        max_gas_fee: parsed_payload['maxFeePerGas'].to_i(16),
        gas_limit: parsed_payload['gas'].to_i(16), # TODO: Handle multiple currencies.
        from: Eth::Address.new(from_address_id),
        to: Eth::Address.new(parsed_payload['to']),
        value: parsed_payload['value'].to_i(16),
        data: parsed_payload['input'] || ''
      }

      @transaction = Eth::Tx::Eip1559.new(Eth::Tx.validate_eip1559_params(params))
      @transaction
    end

    # Returns the status of the Transfer.
    # @return [Symbol] The status
    def status
      @model.status
    end

    def reload
      @model = Coinbase.call_api do
        transfers_api.get_transfer(wallet_id, from_address_id, id)
      end
    end

    # Waits until the Transfer is completed or failed by polling the Network at the given interval. Raises a
    # Timeout::Error if the Transfer takes longer than the given timeout.
    # @param interval_seconds [Integer] The interval at which to poll the Network, in seconds
    # @param timeout_seconds [Integer] The maximum amount of time to wait for the Transfer to complete, in seconds
    # @return [Transfer] The completed Transfer object
    def wait!(interval_seconds = 0.2, timeout_seconds = 10)
      start_time = Time.now

      loop do
        reload

        return self if status == Status::COMPLETE.to_s || status == Status::FAILED.to_s

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
        "asset_id: '#{asset_id}', amount: '#{amount}', transaction_hash: '#{transaction_hash}', " \
        "transaction_link: '#{transaction_link}', status: '#{status}'}"
    end

    # Same as to_s.
    # @return [String] a String representation of the Transfer
    def inspect
      to_s
    end

    def transfers_api
      @transfers_api ||= Coinbase::Client::TransfersApi.new(Coinbase.configuration.api_client)
    end
  end
end

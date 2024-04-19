# frozen_string_literal: true

require_relative 'constants'
require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a Transfer, which moves an amount of an Asset from
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Currently only ETH transfers are supported. Transfers
  # should be created through {link:Wallet#transfer} or {link:Address#transfer}.
  class Transfer
    attr_reader :network_id, :wallet_id, :from_address_id, :amount, :asset_id, :to_address_id

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

    # Returns a new Transfer object.
    # @param network_id [Symbol] The ID of the Network on which the Transfer originated
    # @param wallet_id [String] The ID of the Wallet from which the Transfer originated
    # @param from_address_id [String] The ID of the address from which the Transfer originated
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send. Integers are interpreted as
    #  the smallest denomination of the Asset (e.g. Wei for Ether). Floats and BigDecimals are interpreted as the Asset
    #  itself (e.g. Ether).
    # @param asset_id [Symbol] The ID of the Asset being transferred. Currently only ETH is supported.
    # @param to_address_id [String] The address to which the Transfer is being sent
    # @param client [Jimson::Client] (Optional) The JSON RPC client to use for interacting with the Network
    def initialize(network_id, wallet_id, from_address_id, amount, asset_id, to_address_id,
                   client: Jimson::Client.new(Coinbase.base_sepolia_rpc_url))

      raise ArgumentError, "Unsupported asset: #{asset_id}" if asset_id != :eth

      @network_id = network_id
      @wallet_id = wallet_id
      @from_address_id = from_address_id
      @amount = normalize_eth_amount(amount)
      @asset_id = asset_id
      @to_address_id = to_address_id
      @client = client
    end

    # Returns the underlying Transfer transaction, creating it if it has not been yet.
    # @return [Eth::Tx::Eip1559] The Transfer transaction
    def transaction
      return @transaction unless @transaction.nil?

      nonce = @client.eth_getTransactionCount(@from_address_id.to_s, 'latest').to_i(16)
      gas_price = @client.eth_gasPrice.to_i(16)

      params = {
        chain_id: BASE_SEPOLIA.chain_id, # TODO: Don't hardcode Base Sepolia.
        nonce: nonce,
        priority_fee: gas_price, # TODO: Optimize this.
        max_gas_fee: gas_price,
        gas_limit: 21_000, # TODO: Handle multiple currencies.
        from: Eth::Address.new(@from_address_id),
        to: Eth::Address.new(@to_address_id),
        value: (@amount * Coinbase::WEI_PER_ETHER).to_i
      }

      @transaction = Eth::Tx::Eip1559.new(Eth::Tx.validate_eip1559_params(params))
      @transaction
    end

    # Returns the status of the Transfer.
    # @return [Symbol] The status
    def status
      begin
        # Create the transaction, and attempt to get the hash to see if it has been signed.
        transaction.hash
      rescue Eth::Signature::SignatureError
        # If the transaction has not been signed, it is still pending.
        return Status::PENDING
      end

      onchain_transaction = @client.eth_getTransactionByHash(transaction_hash)

      if onchain_transaction.nil?
        # If the transaction has not been broadcast, it is still pending.
        Status::PENDING
      elsif onchain_transaction['blockHash'].nil?
        # If the transaction has been broadcast but hasn't been included in a block, it is
        # broadcast.
        Status::BROADCAST
      else
        transaction_receipt = @client.eth_getTransactionReceipt(transaction_hash)

        if transaction_receipt['status'].to_i(16) == 1
          Status::COMPLETE
        else
          Status::FAILED
        end
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
        return self if status == Status::COMPLETE || status == Status::FAILED

        raise Timeout::Error, 'Transfer timed out' if Time.now - start_time > timeout_seconds

        self.sleep interval_seconds
      end

      self
    end

    # Returns the transaction hash of the Transfer, or nil if not yet available.
    # @return [String] The transaction hash
    def transaction_hash
      "0x#{transaction.hash}"
    rescue Eth::Signature::SignatureError
      nil
    end

    private

    # Normalizes the given Ether amount into a BigDecimal.
    # @param amount [Integer, Float, BigDecimal] The amount to normalize
    # @return [BigDecimal] The normalized amount
    def normalize_eth_amount(amount)
      case amount
      when BigDecimal
        amount
      when Integer, Float
        BigDecimal(amount.to_s)
      else
        raise ArgumentError, "Invalid amount: #{amount}"
      end
    end
  end
end

# frozen_string_literal: true

module Coinbase
  # A representation of a Transfer, which moves an amount of an Asset from
  # a user-controlled Wallet to another address. The fee is assumed to be paid
  # in the native Asset of the Network. Currently only ETH transfers are supported. Transfers
  # should be created through {link:Wallet#transfer} or {link:Address#transfer}.
  class Transfer
    attr_reader :network_id, :wallet_id, :from_address_id, :amount, :asset_id, :to_address_id, :status

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
                  client: Jimson::Client.new(ENV.fetch('BASE_SEPOLIA_RPC_URL', nil)))

      if asset_id != :eth
        raise ArgumentError, "Unsupported asset: #{asset_id}"
      end

      @network_id = network_id
      @wallet_id = wallet_id
      @from_address_id = from_address_id
      @amount = amount
      @asset_id = asset_id
      @to_address_id = to_address_id
      @client = client
      @status = Status::PENDING
    end

    private

    # Normalizes the given Ether amount into an Integer.
    # @param amount [Integer, Float, BigDecimal] The amount to normalize
    # @return [Integer] The normalized amount
    def normalize_eth_amount(amount)
      case amount
      when Integer
        amount
      when Float, BigDecimal
        amount.to_i * Coinbase::WEI_PER_ETHER
      else
        raise ArgumentError, "Invalid amount: #{amount}"
      end
    end
  end
end

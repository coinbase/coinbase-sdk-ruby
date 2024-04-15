# frozen_string_literal: true

# A representation of a Transfer, which moves an amount of an Asset from
# a user-controlled Wallet to another address. The fee is assumed to be paid
# in the native Asset of the Network. The amount of time it takes for the Swap
# to complete will depend heavily on the Network involved.
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

  # Returns a new Transfer object.
  # @param network_id [Symbol] The ID of the Network on which the Transfer originated
  # @param wallet_id [String] The ID of the Wallet from which the Transfer originated
  # @param from_address_id [String] The address from which the Transfer originated
  # @param to_address_id [String] The address to which the Transfer is being sent
  # @param asset_id [Symbol] The ID of the Asset being transferred
  # @param amount [String] The amount of the Asset being transferred
  # @param fee_amount [String] The amount of the native Asset being paid as a fee
  def initialize(network_id:, wallet_id:, from_address_id:, to_address_id:, asset_id:, amount:, fee_amount:)
    @network_id = network_id
    @wallet_id = wallet_id
    @from_address_id = from_address_id
    @to_address_id = to_address_id
    @asset_id = asset_id
    @amount = amount
    @fee_amount = fee_amount
    @status = Status::PENDING
  end
end

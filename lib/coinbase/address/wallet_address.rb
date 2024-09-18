# frozen_string_literal: true

require 'bigdecimal'
require 'eth'

module Coinbase
  # A representation of a blockchain Address that belongs to a Coinbase::Wallet.
  # Addresses are used to send and receive Assets, and should be created using
  # Wallet#create_address. Addresses require an Eth::Key to sign transaction data.
  class WalletAddress < Address
    # Returns a new Address object. Do not use this method directly. Instead, use Wallet#create_address, or use
    # the Wallet's default_address.
    # @param model [Coinbase::Client::Address] The underlying Address object
    # @param key [Eth::Key] The key backing the Address. Can be nil.
    def initialize(model, key)
      @model = model
      @key = key

      super(model.network_id, model.address_id)
    end

    # Returns the Wallet ID of the Address.
    # @return [String] The Wallet ID
    def wallet_id
      @model.wallet_id
    end

    # Sets the private key backing the Address. This key is used to sign transactions.
    # @param key [Eth::Key] The key backing the Address
    def key=(key)
      raise 'Private key is already set' unless @key.nil?

      @key = key
    end

    # Transfers the given amount of the given Asset to the specified address or wallet.
    # Only same-network Transfers are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param asset_id [Symbol] The ID of the Asset to send. For Ether, :eth, :gwei, and :wei are supported.
    # @param destination [Wallet | Address | String] The destination of the transfer. If a Wallet, sends to the Wallet's
    #  default address. If a String, interprets it as the address ID.
    # @param gasless [Boolean] Whether gas fee for the transfer should be covered by Coinbase.
    #   Defaults to false. Check the API documentation for network and asset support.
    # Whether the transfer should be gasless. Defaults to false.
    # @return [Coinbase::Transfer] The Transfer object.
    def transfer(amount, asset_id, destination, gasless: false)
      ensure_can_sign!
      ensure_sufficient_balance!(amount, asset_id)

      transfer = Transfer.create(
        address_id: id,
        amount: amount,
        asset_id: asset_id,
        destination: destination,
        network: network,
        wallet_id: wallet_id,
        gasless: gasless
      )

      # If a server signer is managing keys, it will sign and broadcast the underlying transfer transaction out of band.
      return transfer if Coinbase.use_server_signer?

      transfer.sign(@key)
      transfer.broadcast!
      transfer
    end

    # Trades the given amount of the given Asset for another Asset.
    # Only same-network Trades are supported.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to send.
    # @param from_asset_id [Symbol] The ID of the Asset to trade from. For Ether, :eth, :gwei, and :wei are supported.
    # @param to_asset_id [Symbol] The ID of the Asset to trade to. For Ether, :eth, :gwei, and :wei are supported.
    # @return [Coinbase::Trade] The Trade object.
    def trade(amount, from_asset_id, to_asset_id)
      ensure_can_sign!
      ensure_sufficient_balance!(amount, from_asset_id)

      trade = Trade.create(
        address_id: id,
        amount: amount,
        from_asset_id: from_asset_id,
        to_asset_id: to_asset_id,
        network: network,
        wallet_id: wallet_id
      )

      # If a server signer is managing keys, it will sign and broadcast the underlying trade transaction out of band.
      return trade if Coinbase.use_server_signer?

      trade.transactions.each do |tx|
        tx.sign(@key)
      end

      trade.broadcast!
      trade
    end

    # Invokes a contract method on the specified contract address, with the given ABI and arguments.
    # @param contract_address [String] The address of the contract to invoke.
    # @param abi [Array<Hash>] The ABI of the contract to invoke.
    # @param method [String] The method to invoke on the contract.
    # @param args [Hash] The arguments to pass to the contract method.
    #   The keys should be the argument names, and the values should be the argument values.
    # @param amount [Integer, Float, BigDecimal] (Optional) The amount of the native Asset
    #   to send to a payable contract method.
    # @param asset_id [Symbol] (Optional) The ID of the Asset to send to a payable contract method.
    #   The Asset must be a denomination of the native Asset. For Ethereum, :eth, :gwei, and :wei are supported.
    # @return [Coinbase::ContractInvocation] The contract invocation object.
    def invoke_contract(contract_address:, abi:, method:, args:, amount: nil, asset_id: nil)
      ensure_can_sign!
      ensure_sufficient_balance!(amount, asset_id) if amount && asset_id

      invocation = ContractInvocation.create(
        address_id: id,
        wallet_id: wallet_id,
        contract_address: contract_address,
        abi: abi,
        method: method,
        args: args,
        amount: amount,
        asset_id: asset_id,
        network: network
      )

      # If a server signer is managing keys, it will sign and broadcast the underlying transaction out of band.
      return invocation if Coinbase.use_server_signer?

      invocation.sign(@key)
      invocation.broadcast!
      invocation
    end

    # Deploys a new ERC20 token contract with the given name, symbol, and total supply.
    # @param name [String] The name of the token.
    # @param symbol [String] The symbol of the token.
    # @param total_supply [Integer, BigDecimal] The total supply of the token, denominated in
    # whole units.
    # @return [Coinbase::SmartContract] The deployed token contract.
    # @raise [AddressCannotSignError] if the Address does not have a private key backing it.
    def deploy_token(name:, symbol:, total_supply:)
      ensure_can_sign!

      smart_contract = SmartContract.create_token_contract(
        address_id: id,
        wallet_id: wallet_id,
        name: name,
        symbol: symbol,
        total_supply: total_supply
      )

      return smart_contract if Coinbase.use_server_signer?

      smart_contract.sign(@key)
      smart_contract.deploy!
      smart_contract
    end

    # Signs the given unsigned payload.
    # @param unsigned_payload [String] The hex-encoded hashed unsigned payload for the Address to sign.
    # @return [Coinbase::PayloadSignature] The payload signature
    def sign_payload(unsigned_payload:)
      ensure_can_sign!

      unless Coinbase.use_server_signer?
        signature = Eth::Util.prefix_hex(@key.sign(Eth::Util.hex_to_bin(unsigned_payload)))
      end

      PayloadSignature.create(
        wallet_id: wallet_id,
        address_id: id,
        unsigned_payload: unsigned_payload,
        signature: signature
      )
    end

    # Stakes the given amount of the given Asset. The stake operation
    # may take a few minutes to complete in the case when infrastructure is spun up.
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to stake.
    # @param asset_id [Symbol] The ID of the Asset to stake. For Ether, :eth, :gwei, and :wei are supported.
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the stake operation. ({StakingOperation#create see_more})
    # @param interval_seconds [Integer] The number of seconds to wait between polling for updates. Defaults to 5.
    # @param timeout_seconds [Integer] The number of seconds to wait before timing out. Defaults to 600.
    # @return [Coinbase::StakingOperation] The staking operation
    # @raise [Timeout::Error] if the Staking Operation takes longer than the given timeout.
    def stake(amount, asset_id, mode: :default, options: {}, interval_seconds: 5, timeout_seconds: 600)
      validate_can_perform_staking_action!(amount, asset_id, 'stakeable_balance', mode, options)

      op = StakingOperation.create(amount, network, asset_id, id, wallet_id, 'stake', mode, options)

      op.complete(@key, interval_seconds: interval_seconds, timeout_seconds: timeout_seconds)
    end

    # Unstakes the given amount of the given Asset
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to unstake.
    # @param asset_id [Symbol] The ID of the Asset to stake. For Ether, :eth, :gwei, and :wei are supported.
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the unstake operation.
    #   ({StakingOperation#create see_more})
    # @param interval_seconds [Integer] The number of seconds to wait between polling for updates. Defaults to 5.
    # @param timeout_seconds [Integer] The number of seconds to wait before timing out. Defaults to 600.
    # @return [Coinbase::StakingOperation] The staking operation
    # @raise [Timeout::Error] if the Staking Operation takes longer than the given timeout.
    def unstake(amount, asset_id, mode: :default, options: {}, interval_seconds: 5, timeout_seconds: 600)
      validate_can_perform_staking_action!(amount, asset_id, 'unstakeable_balance', mode, options)

      op = StakingOperation.create(amount, network, asset_id, id, wallet_id, 'unstake', mode, options)

      op.complete(@key, interval_seconds: interval_seconds, timeout_seconds: timeout_seconds)
    end

    # Claims the given amount of the given Asset
    # @param amount [Integer, Float, BigDecimal] The amount of the Asset to claim.
    # @param asset_id [Symbol] The ID of the Asset to stake. For Ether, :eth, :gwei, and :wei are supported.
    # @param mode [Symbol] The staking mode. Defaults to :default.
    # @param options [Hash] (Optional) Additional options for the claim_stake operation.
    #   ({StakingOperation#create see_more})
    # @param interval_seconds [Integer] The number of seconds to wait between polling for updates. Defaults to 5.
    # @param timeout_seconds [Integer] The number of seconds to wait before timing out. Defaults to 600.
    # @return [Coinbase::StakingOperation] The staking operation
    # @raise [Timeout::Error] if the Staking Operation takes longer than the given timeout.
    def claim_stake(amount, asset_id, mode: :default, options: {}, interval_seconds: 5, timeout_seconds: 600)
      validate_can_perform_staking_action!(amount, asset_id, 'claimable_balance', mode, options)

      op = StakingOperation.create(amount, network, asset_id, id, wallet_id, 'claim_stake', mode, options)

      op.complete(@key, interval_seconds: interval_seconds, timeout_seconds: timeout_seconds)
    end

    # Returns whether the Address has a private key backing it to sign transactions.
    # @return [Boolean] Whether the Address has a private key backing it to sign transactions.
    def can_sign?
      !@key.nil?
    end

    # Exports the Address's private key to a hex string.
    # @return [String] The Address's private key as a hex String
    def export
      raise 'Cannot export key without private key loaded' if @key.nil?

      @key.private_hex
    end

    # Enumerates the transfers associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::Transfer>] Enumerator that returns the address's transfers
    def transfers
      Transfer.list(wallet_id: wallet_id, address_id: id)
    end

    # Enumerates the trades associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::Trade>] Enumerator that returns the address's trades
    def trades
      Trade.list(wallet_id: wallet_id, address_id: id)
    end

    # Enumerates the payload signatures associated with the address.
    # The result is an enumerator that lazily fetches from the server, and can be iterated over,
    # converted to an array, etc...
    # @return [Enumerable<Coinbase::PayloadSignature>] Enumerator that returns the address's payload signatures
    def payload_signatures
      PayloadSignature.list(wallet_id: wallet_id, address_id: id)
    end

    # Returns a String representation of the WalletAddress.
    # @return [String] a String representation of the WalletAddress
    def to_s
      "Coinbase::Address{id: '#{id}', network_id: '#{network.id}', wallet_id: '#{wallet_id}'}"
    end

    private

    def ensure_can_sign!
      return if Coinbase.use_server_signer?
      return if can_sign?

      raise AddressCannotSignError
    end

    def ensure_sufficient_balance!(amount, asset_id)
      current_balance = balance(asset_id)

      return unless current_balance < amount

      raise InsufficientFundsError.new(amount, current_balance)
    end
  end
end

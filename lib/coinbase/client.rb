=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.5.0

=end

# Common files
require 'coinbase/client/api_client'
require 'coinbase/client/api_error'
require 'coinbase/client/version'
require 'coinbase/client/configuration'

# Models
Coinbase::Client.autoload :Address, 'coinbase/client/models/address'
Coinbase::Client.autoload :AddressBalanceList, 'coinbase/client/models/address_balance_list'
Coinbase::Client.autoload :AddressList, 'coinbase/client/models/address_list'
Coinbase::Client.autoload :Asset, 'coinbase/client/models/asset'
Coinbase::Client.autoload :Balance, 'coinbase/client/models/balance'
Coinbase::Client.autoload :BroadcastTransferRequest, 'coinbase/client/models/broadcast_transfer_request'
Coinbase::Client.autoload :CreateAddressRequest, 'coinbase/client/models/create_address_request'
Coinbase::Client.autoload :CreateServerSignerRequest, 'coinbase/client/models/create_server_signer_request'
Coinbase::Client.autoload :CreateTransferRequest, 'coinbase/client/models/create_transfer_request'
Coinbase::Client.autoload :CreateWalletRequest, 'coinbase/client/models/create_wallet_request'
Coinbase::Client.autoload :CreateWalletRequestWallet, 'coinbase/client/models/create_wallet_request_wallet'
Coinbase::Client.autoload :Error, 'coinbase/client/models/error'
Coinbase::Client.autoload :FaucetTransaction, 'coinbase/client/models/faucet_transaction'
Coinbase::Client.autoload :SeedCreationEvent, 'coinbase/client/models/seed_creation_event'
Coinbase::Client.autoload :ServerSigner, 'coinbase/client/models/server_signer'
Coinbase::Client.autoload :ServerSignerEvent, 'coinbase/client/models/server_signer_event'
Coinbase::Client.autoload :ServerSignerEventEvent, 'coinbase/client/models/server_signer_event_event'
Coinbase::Client.autoload :SignatureCreationEvent, 'coinbase/client/models/signature_creation_event'
Coinbase::Client.autoload :Transfer, 'coinbase/client/models/transfer'
Coinbase::Client.autoload :TransferList, 'coinbase/client/models/transfer_list'
Coinbase::Client.autoload :User, 'coinbase/client/models/user'
Coinbase::Client.autoload :Wallet, 'coinbase/client/models/wallet'
Coinbase::Client.autoload :WalletList, 'coinbase/client/models/wallet_list'

# APIs
Coinbase::Client.autoload :AddressesApi, 'coinbase/client/api/addresses_api'
Coinbase::Client.autoload :ServerSignersApi, 'coinbase/client/api/server_signers_api'
Coinbase::Client.autoload :TransfersApi, 'coinbase/client/api/transfers_api'
Coinbase::Client.autoload :UsersApi, 'coinbase/client/api/users_api'
Coinbase::Client.autoload :WalletsApi, 'coinbase/client/api/wallets_api'

module Coinbase::Client
  class << self
    # Customize default settings for the SDK using block.
    #   Coinbase::Client.configure do |config|
    #     config.username = "xxx"
    #     config.password = "xxx"
    #   end
    # If no block given, return the default Configuration object.
    def configure
      if block_given?
        yield(Configuration.default)
      else
        Configuration.default
      end
    end
  end
end

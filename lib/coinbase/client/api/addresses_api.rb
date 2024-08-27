=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.7.0

=end

require 'cgi'

module Coinbase::Client
  class AddressesApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Create a new address
    # Create a new address scoped to the wallet.
    # @param wallet_id [String] The ID of the wallet to create the address in.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateAddressRequest] :create_address_request 
    # @return [Address]
    def create_address(wallet_id, opts = {})
      data, _status_code, _headers = create_address_with_http_info(wallet_id, opts)
      data
    end

    # Create a new address
    # Create a new address scoped to the wallet.
    # @param wallet_id [String] The ID of the wallet to create the address in.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateAddressRequest] :create_address_request 
    # @return [Array<(Address, Integer, Hash)>] Address data, response status code and response headers
    def create_address_with_http_info(wallet_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.create_address ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.create_address"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])
      # HTTP header 'Content-Type'
      content_type = @api_client.select_header_content_type(['application/json'])
      if !content_type.nil?
          header_params['Content-Type'] = content_type
      end

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'create_address_request'])

      # return_type
      return_type = opts[:debug_return_type] || 'Address'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.create_address",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#create_address\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get address by onchain address
    # Get address
    # @param wallet_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @return [Address]
    def get_address(wallet_id, address_id, opts = {})
      data, _status_code, _headers = get_address_with_http_info(wallet_id, address_id, opts)
      data
    end

    # Get address by onchain address
    # Get address
    # @param wallet_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @return [Array<(Address, Integer, Hash)>] Address data, response status code and response headers
    def get_address_with_http_info(wallet_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.get_address ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.get_address"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling AddressesApi.get_address"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'Address'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.get_address",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#get_address\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get address balance for asset
    # Get address balance
    # @param wallet_id [String] The ID of the wallet to fetch the balance for
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param asset_id [String] The symbol of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Balance]
    def get_address_balance(wallet_id, address_id, asset_id, opts = {})
      data, _status_code, _headers = get_address_balance_with_http_info(wallet_id, address_id, asset_id, opts)
      data
    end

    # Get address balance for asset
    # Get address balance
    # @param wallet_id [String] The ID of the wallet to fetch the balance for
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param asset_id [String] The symbol of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Array<(Balance, Integer, Hash)>] Balance data, response status code and response headers
    def get_address_balance_with_http_info(wallet_id, address_id, asset_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.get_address_balance ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.get_address_balance"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling AddressesApi.get_address_balance"
      end
      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling AddressesApi.get_address_balance"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/balances/{asset_id}'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'asset_id' + '}', CGI.escape(asset_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'Balance'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.get_address_balance",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#get_address_balance\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get all balances for address
    # Get address balances
    # @param wallet_id [String] The ID of the wallet to fetch the balances for
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [AddressBalanceList]
    def list_address_balances(wallet_id, address_id, opts = {})
      data, _status_code, _headers = list_address_balances_with_http_info(wallet_id, address_id, opts)
      data
    end

    # Get all balances for address
    # Get address balances
    # @param wallet_id [String] The ID of the wallet to fetch the balances for
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(AddressBalanceList, Integer, Hash)>] AddressBalanceList data, response status code and response headers
    def list_address_balances_with_http_info(wallet_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.list_address_balances ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.list_address_balances"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling AddressesApi.list_address_balances"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling AddressesApi.list_address_balances, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/balances'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'page'] = opts[:'page'] if !opts[:'page'].nil?

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'AddressBalanceList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.list_address_balances",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#list_address_balances\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List addresses in a wallet.
    # List addresses in the wallet.
    # @param wallet_id [String] The ID of the wallet whose addresses to fetch
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [AddressList]
    def list_addresses(wallet_id, opts = {})
      data, _status_code, _headers = list_addresses_with_http_info(wallet_id, opts)
      data
    end

    # List addresses in a wallet.
    # List addresses in the wallet.
    # @param wallet_id [String] The ID of the wallet whose addresses to fetch
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(AddressList, Integer, Hash)>] AddressList data, response status code and response headers
    def list_addresses_with_http_info(wallet_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.list_addresses ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.list_addresses"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling AddressesApi.list_addresses, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'limit'] = opts[:'limit'] if !opts[:'limit'].nil?
      query_params[:'page'] = opts[:'page'] if !opts[:'page'].nil?

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'AddressList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.list_addresses",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#list_addresses\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Request faucet funds for onchain address.
    # Request faucet funds to be sent to onchain address.
    # @param wallet_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :asset_id The ID of the asset to transfer from the faucet.
    # @return [FaucetTransaction]
    def request_faucet_funds(wallet_id, address_id, opts = {})
      data, _status_code, _headers = request_faucet_funds_with_http_info(wallet_id, address_id, opts)
      data
    end

    # Request faucet funds for onchain address.
    # Request faucet funds to be sent to onchain address.
    # @param wallet_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :asset_id The ID of the asset to transfer from the faucet.
    # @return [Array<(FaucetTransaction, Integer, Hash)>] FaucetTransaction data, response status code and response headers
    def request_faucet_funds_with_http_info(wallet_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AddressesApi.request_faucet_funds ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling AddressesApi.request_faucet_funds"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling AddressesApi.request_faucet_funds"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/faucet'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'asset_id'] = opts[:'asset_id'] if !opts[:'asset_id'].nil?

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json'])

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'FaucetTransaction'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AddressesApi.request_faucet_funds",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AddressesApi#request_faucet_funds\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

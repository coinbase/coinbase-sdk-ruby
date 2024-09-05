=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.7.0

=end

require 'cgi'

module Coinbase::Client
  class ExternalAddressesApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Get the balance of an asset in an external address
    # Get the balance of an asset in an external address
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the balance for
    # @param asset_id [String] The ID of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Balance]
    def get_external_address_balance(network_id, address_id, asset_id, opts = {})
      data, _status_code, _headers = get_external_address_balance_with_http_info(network_id, address_id, asset_id, opts)
      data
    end

    # Get the balance of an asset in an external address
    # Get the balance of an asset in an external address
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the balance for
    # @param asset_id [String] The ID of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Array<(Balance, Integer, Hash)>] Balance data, response status code and response headers
    def get_external_address_balance_with_http_info(network_id, address_id, asset_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ExternalAddressesApi.get_external_address_balance ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ExternalAddressesApi.get_external_address_balance"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling ExternalAddressesApi.get_external_address_balance"
      end
      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling ExternalAddressesApi.get_external_address_balance"
      end
      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/balances/{asset_id}'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'asset_id' + '}', CGI.escape(asset_id.to_s))

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
        :operation => :"ExternalAddressesApi.get_external_address_balance",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ExternalAddressesApi#get_external_address_balance\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get address balance history for asset
    # List the historical balance of an asset in a specific address.
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the historical balance for.
    # @param asset_id [String] The symbol of the asset to fetch the historical balance for.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [AddressHistoricalBalanceList]
    def list_address_historical_balance(network_id, address_id, asset_id, opts = {})
      data, _status_code, _headers = list_address_historical_balance_with_http_info(network_id, address_id, asset_id, opts)
      data
    end

    # Get address balance history for asset
    # List the historical balance of an asset in a specific address.
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the historical balance for.
    # @param asset_id [String] The symbol of the asset to fetch the historical balance for.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(AddressHistoricalBalanceList, Integer, Hash)>] AddressHistoricalBalanceList data, response status code and response headers
    def list_address_historical_balance_with_http_info(network_id, address_id, asset_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ExternalAddressesApi.list_address_historical_balance ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ExternalAddressesApi.list_address_historical_balance"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling ExternalAddressesApi.list_address_historical_balance"
      end
      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling ExternalAddressesApi.list_address_historical_balance"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling ExternalAddressesApi.list_address_historical_balance, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/balance_history/{asset_id}'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'asset_id' + '}', CGI.escape(asset_id.to_s))

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
      return_type = opts[:debug_return_type] || 'AddressHistoricalBalanceList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"ExternalAddressesApi.list_address_historical_balance",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ExternalAddressesApi#list_address_historical_balance\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List transactions for an address.
    # List all transactions that interact with the address.
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the transactions for.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [AddressTransactionList]
    def list_address_transactions(network_id, address_id, opts = {})
      data, _status_code, _headers = list_address_transactions_with_http_info(network_id, address_id, opts)
      data
    end

    # List transactions for an address.
    # List all transactions that interact with the address.
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the transactions for.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(AddressTransactionList, Integer, Hash)>] AddressTransactionList data, response status code and response headers
    def list_address_transactions_with_http_info(network_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ExternalAddressesApi.list_address_transactions ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ExternalAddressesApi.list_address_transactions"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling ExternalAddressesApi.list_address_transactions"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling ExternalAddressesApi.list_address_transactions, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/transactions'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
      return_type = opts[:debug_return_type] || 'AddressTransactionList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"ExternalAddressesApi.list_address_transactions",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ExternalAddressesApi#list_address_transactions\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get the balances of an external address
    # List all of the balances of an external address
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [AddressBalanceList]
    def list_external_address_balances(network_id, address_id, opts = {})
      data, _status_code, _headers = list_external_address_balances_with_http_info(network_id, address_id, opts)
      data
    end

    # Get the balances of an external address
    # List all of the balances of an external address
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(AddressBalanceList, Integer, Hash)>] AddressBalanceList data, response status code and response headers
    def list_external_address_balances_with_http_info(network_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ExternalAddressesApi.list_external_address_balances ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ExternalAddressesApi.list_external_address_balances"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling ExternalAddressesApi.list_external_address_balances"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling ExternalAddressesApi.list_external_address_balances, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/balances'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
        :operation => :"ExternalAddressesApi.list_external_address_balances",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ExternalAddressesApi#list_external_address_balances\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Request faucet funds for external address.
    # Request faucet funds to be sent to external address.
    # @param network_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :asset_id The ID of the asset to transfer from the faucet.
    # @return [FaucetTransaction]
    def request_external_faucet_funds(network_id, address_id, opts = {})
      data, _status_code, _headers = request_external_faucet_funds_with_http_info(network_id, address_id, opts)
      data
    end

    # Request faucet funds for external address.
    # Request faucet funds to be sent to external address.
    # @param network_id [String] The ID of the wallet the address belongs to.
    # @param address_id [String] The onchain address of the address that is being fetched.
    # @param [Hash] opts the optional parameters
    # @option opts [String] :asset_id The ID of the asset to transfer from the faucet.
    # @return [Array<(FaucetTransaction, Integer, Hash)>] FaucetTransaction data, response status code and response headers
    def request_external_faucet_funds_with_http_info(network_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ExternalAddressesApi.request_external_faucet_funds ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ExternalAddressesApi.request_external_faucet_funds"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling ExternalAddressesApi.request_external_faucet_funds"
      end
      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/faucet'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
        :operation => :"ExternalAddressesApi.request_external_faucet_funds",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ExternalAddressesApi#request_external_faucet_funds\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

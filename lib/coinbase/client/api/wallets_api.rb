=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.9.0

=end

require 'cgi'

module Coinbase::Client
  class WalletsApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Create a new wallet
    # Create a new wallet scoped to the user.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWalletRequest] :create_wallet_request 
    # @return [Wallet]
    def create_wallet(opts = {})
      data, _status_code, _headers = create_wallet_with_http_info(opts)
      data
    end

    # Create a new wallet
    # Create a new wallet scoped to the user.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWalletRequest] :create_wallet_request 
    # @return [Array<(Wallet, Integer, Hash)>] Wallet data, response status code and response headers
    def create_wallet_with_http_info(opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WalletsApi.create_wallet ...'
      end
      # resource path
      local_var_path = '/v1/wallets'

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']
      # HTTP header 'Content-Type'
      content_type = @api_client.select_header_content_type(['application/json'])
      if !content_type.nil?
          header_params['Content-Type'] = content_type
      end

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'create_wallet_request'])

      # return_type
      return_type = opts[:debug_return_type] || 'Wallet'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WalletsApi.create_wallet",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WalletsApi#create_wallet\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get wallet by ID
    # Get wallet
    # @param wallet_id [String] The ID of the wallet to fetch
    # @param [Hash] opts the optional parameters
    # @return [Wallet]
    def get_wallet(wallet_id, opts = {})
      data, _status_code, _headers = get_wallet_with_http_info(wallet_id, opts)
      data
    end

    # Get wallet by ID
    # Get wallet
    # @param wallet_id [String] The ID of the wallet to fetch
    # @param [Hash] opts the optional parameters
    # @return [Array<(Wallet, Integer, Hash)>] Wallet data, response status code and response headers
    def get_wallet_with_http_info(wallet_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WalletsApi.get_wallet ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling WalletsApi.get_wallet"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'Wallet'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WalletsApi.get_wallet",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WalletsApi#get_wallet\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get the balance of an asset in the wallet
    # Get the aggregated balance of an asset across all of the addresses in the wallet.
    # @param wallet_id [String] The ID of the wallet to fetch the balance for
    # @param asset_id [String] The symbol of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Balance]
    def get_wallet_balance(wallet_id, asset_id, opts = {})
      data, _status_code, _headers = get_wallet_balance_with_http_info(wallet_id, asset_id, opts)
      data
    end

    # Get the balance of an asset in the wallet
    # Get the aggregated balance of an asset across all of the addresses in the wallet.
    # @param wallet_id [String] The ID of the wallet to fetch the balance for
    # @param asset_id [String] The symbol of the asset to fetch the balance for
    # @param [Hash] opts the optional parameters
    # @return [Array<(Balance, Integer, Hash)>] Balance data, response status code and response headers
    def get_wallet_balance_with_http_info(wallet_id, asset_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WalletsApi.get_wallet_balance ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling WalletsApi.get_wallet_balance"
      end
      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling WalletsApi.get_wallet_balance"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/balances/{asset_id}'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'asset_id' + '}', CGI.escape(asset_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'Balance'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WalletsApi.get_wallet_balance",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WalletsApi#get_wallet_balance\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List wallet balances
    # List the balances of all of the addresses in the wallet aggregated by asset.
    # @param wallet_id [String] The ID of the wallet to fetch the balances for
    # @param [Hash] opts the optional parameters
    # @return [AddressBalanceList]
    def list_wallet_balances(wallet_id, opts = {})
      data, _status_code, _headers = list_wallet_balances_with_http_info(wallet_id, opts)
      data
    end

    # List wallet balances
    # List the balances of all of the addresses in the wallet aggregated by asset.
    # @param wallet_id [String] The ID of the wallet to fetch the balances for
    # @param [Hash] opts the optional parameters
    # @return [Array<(AddressBalanceList, Integer, Hash)>] AddressBalanceList data, response status code and response headers
    def list_wallet_balances_with_http_info(wallet_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WalletsApi.list_wallet_balances ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling WalletsApi.list_wallet_balances"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/balances'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'AddressBalanceList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WalletsApi.list_wallet_balances",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WalletsApi#list_wallet_balances\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List wallets
    # List wallets belonging to the user.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [WalletList]
    def list_wallets(opts = {})
      data, _status_code, _headers = list_wallets_with_http_info(opts)
      data
    end

    # List wallets
    # List wallets belonging to the user.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(WalletList, Integer, Hash)>] WalletList data, response status code and response headers
    def list_wallets_with_http_info(opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WalletsApi.list_wallets ...'
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling WalletsApi.list_wallets, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/wallets'

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'limit'] = opts[:'limit'] if !opts[:'limit'].nil?
      query_params[:'page'] = opts[:'page'] if !opts[:'page'].nil?

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'WalletList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WalletsApi.list_wallets",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WalletsApi#list_wallets\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

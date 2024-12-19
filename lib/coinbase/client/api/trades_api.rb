=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.10.0

=end

require 'cgi'

module Coinbase::Client
  class TradesApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Broadcast a trade
    # Broadcast a trade
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address the trade belongs to
    # @param trade_id [String] The ID of the trade to broadcast
    # @param broadcast_trade_request [BroadcastTradeRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Trade]
    def broadcast_trade(wallet_id, address_id, trade_id, broadcast_trade_request, opts = {})
      data, _status_code, _headers = broadcast_trade_with_http_info(wallet_id, address_id, trade_id, broadcast_trade_request, opts)
      data
    end

    # Broadcast a trade
    # Broadcast a trade
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address the trade belongs to
    # @param trade_id [String] The ID of the trade to broadcast
    # @param broadcast_trade_request [BroadcastTradeRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Array<(Trade, Integer, Hash)>] Trade data, response status code and response headers
    def broadcast_trade_with_http_info(wallet_id, address_id, trade_id, broadcast_trade_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: TradesApi.broadcast_trade ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling TradesApi.broadcast_trade"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling TradesApi.broadcast_trade"
      end
      # verify the required parameter 'trade_id' is set
      if @api_client.config.client_side_validation && trade_id.nil?
        fail ArgumentError, "Missing the required parameter 'trade_id' when calling TradesApi.broadcast_trade"
      end
      # verify the required parameter 'broadcast_trade_request' is set
      if @api_client.config.client_side_validation && broadcast_trade_request.nil?
        fail ArgumentError, "Missing the required parameter 'broadcast_trade_request' when calling TradesApi.broadcast_trade"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/trades/{trade_id}/broadcast'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'trade_id' + '}', CGI.escape(trade_id.to_s))

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(broadcast_trade_request)

      # return_type
      return_type = opts[:debug_return_type] || 'Trade'

      # auth_names
      auth_names = opts[:debug_auth_names] || ['apiKey']

      new_options = opts.merge(
        :operation => :"TradesApi.broadcast_trade",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: TradesApi#broadcast_trade\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Create a new trade for an address
    # Create a new trade
    # @param wallet_id [String] The ID of the wallet the source address belongs to
    # @param address_id [String] The ID of the address to conduct the trade from
    # @param create_trade_request [CreateTradeRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Trade]
    def create_trade(wallet_id, address_id, create_trade_request, opts = {})
      data, _status_code, _headers = create_trade_with_http_info(wallet_id, address_id, create_trade_request, opts)
      data
    end

    # Create a new trade for an address
    # Create a new trade
    # @param wallet_id [String] The ID of the wallet the source address belongs to
    # @param address_id [String] The ID of the address to conduct the trade from
    # @param create_trade_request [CreateTradeRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Array<(Trade, Integer, Hash)>] Trade data, response status code and response headers
    def create_trade_with_http_info(wallet_id, address_id, create_trade_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: TradesApi.create_trade ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling TradesApi.create_trade"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling TradesApi.create_trade"
      end
      # verify the required parameter 'create_trade_request' is set
      if @api_client.config.client_side_validation && create_trade_request.nil?
        fail ArgumentError, "Missing the required parameter 'create_trade_request' when calling TradesApi.create_trade"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/trades'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(create_trade_request)

      # return_type
      return_type = opts[:debug_return_type] || 'Trade'

      # auth_names
      auth_names = opts[:debug_auth_names] || ['apiKey']

      new_options = opts.merge(
        :operation => :"TradesApi.create_trade",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: TradesApi#create_trade\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get a trade by ID
    # Get a trade by ID
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address the trade belongs to
    # @param trade_id [String] The ID of the trade to fetch
    # @param [Hash] opts the optional parameters
    # @return [Trade]
    def get_trade(wallet_id, address_id, trade_id, opts = {})
      data, _status_code, _headers = get_trade_with_http_info(wallet_id, address_id, trade_id, opts)
      data
    end

    # Get a trade by ID
    # Get a trade by ID
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address the trade belongs to
    # @param trade_id [String] The ID of the trade to fetch
    # @param [Hash] opts the optional parameters
    # @return [Array<(Trade, Integer, Hash)>] Trade data, response status code and response headers
    def get_trade_with_http_info(wallet_id, address_id, trade_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: TradesApi.get_trade ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling TradesApi.get_trade"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling TradesApi.get_trade"
      end
      # verify the required parameter 'trade_id' is set
      if @api_client.config.client_side_validation && trade_id.nil?
        fail ArgumentError, "Missing the required parameter 'trade_id' when calling TradesApi.get_trade"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/trades/{trade_id}'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'trade_id' + '}', CGI.escape(trade_id.to_s))

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
      return_type = opts[:debug_return_type] || 'Trade'

      # auth_names
      auth_names = opts[:debug_auth_names] || ['apiKey', 'session']

      new_options = opts.merge(
        :operation => :"TradesApi.get_trade",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: TradesApi#get_trade\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List trades for an address.
    # List trades for an address.
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address to list trades for
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [TradeList]
    def list_trades(wallet_id, address_id, opts = {})
      data, _status_code, _headers = list_trades_with_http_info(wallet_id, address_id, opts)
      data
    end

    # List trades for an address.
    # List trades for an address.
    # @param wallet_id [String] The ID of the wallet the address belongs to
    # @param address_id [String] The ID of the address to list trades for
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(TradeList, Integer, Hash)>] TradeList data, response status code and response headers
    def list_trades_with_http_info(wallet_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: TradesApi.list_trades ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling TradesApi.list_trades"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling TradesApi.list_trades"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling TradesApi.list_trades, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/trades'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
      return_type = opts[:debug_return_type] || 'TradeList'

      # auth_names
      auth_names = opts[:debug_auth_names] || ['apiKey', 'session']

      new_options = opts.merge(
        :operation => :"TradesApi.list_trades",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: TradesApi#list_trades\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

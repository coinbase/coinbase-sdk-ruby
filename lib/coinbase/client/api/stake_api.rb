=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.8.0

=end

require 'cgi'

module Coinbase::Client
  class StakeApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Build a new staking operation
    # Build a new staking operation
    # @param build_staking_operation_request [BuildStakingOperationRequest] 
    # @param [Hash] opts the optional parameters
    # @return [StakingOperation]
    def build_staking_operation(build_staking_operation_request, opts = {})
      data, _status_code, _headers = build_staking_operation_with_http_info(build_staking_operation_request, opts)
      data
    end

    # Build a new staking operation
    # Build a new staking operation
    # @param build_staking_operation_request [BuildStakingOperationRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Array<(StakingOperation, Integer, Hash)>] StakingOperation data, response status code and response headers
    def build_staking_operation_with_http_info(build_staking_operation_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.build_staking_operation ...'
      end
      # verify the required parameter 'build_staking_operation_request' is set
      if @api_client.config.client_side_validation && build_staking_operation_request.nil?
        fail ArgumentError, "Missing the required parameter 'build_staking_operation_request' when calling StakeApi.build_staking_operation"
      end
      # resource path
      local_var_path = '/v1/stake/build'

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(build_staking_operation_request)

      # return_type
      return_type = opts[:debug_return_type] || 'StakingOperation'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"StakeApi.build_staking_operation",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: StakeApi#build_staking_operation\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Fetch historical staking balances
    # Fetch historical staking balances for given address.
    # @param network_id [String] The ID of the blockchain network.
    # @param asset_id [String] The ID of the asset for which the historical staking balances are being fetched.
    # @param address_id [String] The onchain address for which the historical staking balances are being fetched.
    # @param start_time [Time] The start time of this historical staking balance period.
    # @param end_time [Time] The end time of this historical staking balance period.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 50.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [FetchHistoricalStakingBalances200Response]
    def fetch_historical_staking_balances(network_id, asset_id, address_id, start_time, end_time, opts = {})
      data, _status_code, _headers = fetch_historical_staking_balances_with_http_info(network_id, asset_id, address_id, start_time, end_time, opts)
      data
    end

    # Fetch historical staking balances
    # Fetch historical staking balances for given address.
    # @param network_id [String] The ID of the blockchain network.
    # @param asset_id [String] The ID of the asset for which the historical staking balances are being fetched.
    # @param address_id [String] The onchain address for which the historical staking balances are being fetched.
    # @param start_time [Time] The start time of this historical staking balance period.
    # @param end_time [Time] The end time of this historical staking balance period.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 50.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(FetchHistoricalStakingBalances200Response, Integer, Hash)>] FetchHistoricalStakingBalances200Response data, response status code and response headers
    def fetch_historical_staking_balances_with_http_info(network_id, asset_id, address_id, start_time, end_time, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.fetch_historical_staking_balances ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling StakeApi.fetch_historical_staking_balances"
      end
      if @api_client.config.client_side_validation && network_id.to_s.length > 5000
        fail ArgumentError, 'invalid value for "network_id" when calling StakeApi.fetch_historical_staking_balances, the character length must be smaller than or equal to 5000.'
      end

      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling StakeApi.fetch_historical_staking_balances"
      end
      if @api_client.config.client_side_validation && asset_id.to_s.length > 5000
        fail ArgumentError, 'invalid value for "asset_id" when calling StakeApi.fetch_historical_staking_balances, the character length must be smaller than or equal to 5000.'
      end

      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling StakeApi.fetch_historical_staking_balances"
      end
      if @api_client.config.client_side_validation && address_id.to_s.length > 5000
        fail ArgumentError, 'invalid value for "address_id" when calling StakeApi.fetch_historical_staking_balances, the character length must be smaller than or equal to 5000.'
      end

      # verify the required parameter 'start_time' is set
      if @api_client.config.client_side_validation && start_time.nil?
        fail ArgumentError, "Missing the required parameter 'start_time' when calling StakeApi.fetch_historical_staking_balances"
      end
      # verify the required parameter 'end_time' is set
      if @api_client.config.client_side_validation && end_time.nil?
        fail ArgumentError, "Missing the required parameter 'end_time' when calling StakeApi.fetch_historical_staking_balances"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling StakeApi.fetch_historical_staking_balances, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/stake/balances'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'asset_id'] = asset_id
      query_params[:'start_time'] = start_time
      query_params[:'end_time'] = end_time
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
      return_type = opts[:debug_return_type] || 'FetchHistoricalStakingBalances200Response'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"StakeApi.fetch_historical_staking_balances",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: StakeApi#fetch_historical_staking_balances\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Fetch staking rewards
    # Fetch staking rewards for a list of addresses
    # @param fetch_staking_rewards_request [FetchStakingRewardsRequest] 
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 50.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [FetchStakingRewards200Response]
    def fetch_staking_rewards(fetch_staking_rewards_request, opts = {})
      data, _status_code, _headers = fetch_staking_rewards_with_http_info(fetch_staking_rewards_request, opts)
      data
    end

    # Fetch staking rewards
    # Fetch staking rewards for a list of addresses
    # @param fetch_staking_rewards_request [FetchStakingRewardsRequest] 
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 50.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(FetchStakingRewards200Response, Integer, Hash)>] FetchStakingRewards200Response data, response status code and response headers
    def fetch_staking_rewards_with_http_info(fetch_staking_rewards_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.fetch_staking_rewards ...'
      end
      # verify the required parameter 'fetch_staking_rewards_request' is set
      if @api_client.config.client_side_validation && fetch_staking_rewards_request.nil?
        fail ArgumentError, "Missing the required parameter 'fetch_staking_rewards_request' when calling StakeApi.fetch_staking_rewards"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling StakeApi.fetch_staking_rewards, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/stake/rewards/search'

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'limit'] = opts[:'limit'] if !opts[:'limit'].nil?
      query_params[:'page'] = opts[:'page'] if !opts[:'page'].nil?

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(fetch_staking_rewards_request)

      # return_type
      return_type = opts[:debug_return_type] || 'FetchStakingRewards200Response'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"StakeApi.fetch_staking_rewards",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: StakeApi#fetch_staking_rewards\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get the latest state of a staking operation
    # Get the latest state of a staking operation
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the staking operation for
    # @param staking_operation_id [String] The ID of the staking operation
    # @param [Hash] opts the optional parameters
    # @return [StakingOperation]
    def get_external_staking_operation(network_id, address_id, staking_operation_id, opts = {})
      data, _status_code, _headers = get_external_staking_operation_with_http_info(network_id, address_id, staking_operation_id, opts)
      data
    end

    # Get the latest state of a staking operation
    # Get the latest state of a staking operation
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the staking operation for
    # @param staking_operation_id [String] The ID of the staking operation
    # @param [Hash] opts the optional parameters
    # @return [Array<(StakingOperation, Integer, Hash)>] StakingOperation data, response status code and response headers
    def get_external_staking_operation_with_http_info(network_id, address_id, staking_operation_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.get_external_staking_operation ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling StakeApi.get_external_staking_operation"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling StakeApi.get_external_staking_operation"
      end
      # verify the required parameter 'staking_operation_id' is set
      if @api_client.config.client_side_validation && staking_operation_id.nil?
        fail ArgumentError, "Missing the required parameter 'staking_operation_id' when calling StakeApi.get_external_staking_operation"
      end
      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/staking_operations/{staking_operation_id}'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s)).sub('{' + 'staking_operation_id' + '}', CGI.escape(staking_operation_id.to_s))

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
      return_type = opts[:debug_return_type] || 'StakingOperation'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"StakeApi.get_external_staking_operation",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: StakeApi#get_external_staking_operation\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Get staking context
    # Get staking context for an address
    # @param get_staking_context_request [GetStakingContextRequest] 
    # @param [Hash] opts the optional parameters
    # @return [StakingContext]
    def get_staking_context(get_staking_context_request, opts = {})
      data, _status_code, _headers = get_staking_context_with_http_info(get_staking_context_request, opts)
      data
    end

    # Get staking context
    # Get staking context for an address
    # @param get_staking_context_request [GetStakingContextRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Array<(StakingContext, Integer, Hash)>] StakingContext data, response status code and response headers
    def get_staking_context_with_http_info(get_staking_context_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.get_staking_context ...'
      end
      # verify the required parameter 'get_staking_context_request' is set
      if @api_client.config.client_side_validation && get_staking_context_request.nil?
        fail ArgumentError, "Missing the required parameter 'get_staking_context_request' when calling StakeApi.get_staking_context"
      end
      # resource path
      local_var_path = '/v1/stake/context'

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(get_staking_context_request)

      # return_type
      return_type = opts[:debug_return_type] || 'StakingContext'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"StakeApi.get_staking_context",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: StakeApi#get_staking_context\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

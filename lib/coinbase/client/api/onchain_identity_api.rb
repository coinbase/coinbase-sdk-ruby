=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.9.0

=end

require 'cgi'

module Coinbase::Client
  class OnchainIdentityApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Obtains onchain identity for an address on a specific network
    # Obtains onchain identity for an address on a specific network
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the identity for
    # @param [Hash] opts the optional parameters
    # @option opts [Array<String>] :roles A filter by role of the names related to this address (managed or owned)
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [OnchainNameList]
    def resolve_identity_by_address(network_id, address_id, opts = {})
      data, _status_code, _headers = resolve_identity_by_address_with_http_info(network_id, address_id, opts)
      data
    end

    # Obtains onchain identity for an address on a specific network
    # Obtains onchain identity for an address on a specific network
    # @param network_id [String] The ID of the blockchain network
    # @param address_id [String] The ID of the address to fetch the identity for
    # @param [Hash] opts the optional parameters
    # @option opts [Array<String>] :roles A filter by role of the names related to this address (managed or owned)
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(OnchainNameList, Integer, Hash)>] OnchainNameList data, response status code and response headers
    def resolve_identity_by_address_with_http_info(network_id, address_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: OnchainIdentityApi.resolve_identity_by_address ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling OnchainIdentityApi.resolve_identity_by_address"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling OnchainIdentityApi.resolve_identity_by_address"
      end
      allowable_values = ["managed", "owned", "unknown_default_open_api"]
      if @api_client.config.client_side_validation && opts[:'roles'] && !opts[:'roles'].all? { |item| allowable_values.include?(item) }
        fail ArgumentError, "invalid value for \"roles\", must include one of #{allowable_values}"
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling OnchainIdentityApi.resolve_identity_by_address, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/networks/{network_id}/addresses/{address_id}/identity'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'roles'] = @api_client.build_collection_param(opts[:'roles'], :csv) if !opts[:'roles'].nil?
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
      return_type = opts[:debug_return_type] || 'OnchainNameList'

      # auth_names
      auth_names = opts[:debug_auth_names] || ['apiKey', 'session']

      new_options = opts.merge(
        :operation => :"OnchainIdentityApi.resolve_identity_by_address",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: OnchainIdentityApi#resolve_identity_by_address\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

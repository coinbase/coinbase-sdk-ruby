=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.8.0

=end

require 'cgi'

module Coinbase::Client
  class AssetsApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Get the asset for the specified asset ID.
    # Get the asset for the specified asset ID.
    # @param network_id [String] The ID of the blockchain network
    # @param asset_id [String] The ID of the asset to fetch. This could be a symbol or an ERC20 contract address.
    # @param [Hash] opts the optional parameters
    # @return [Asset]
    def get_asset(network_id, asset_id, opts = {})
      data, _status_code, _headers = get_asset_with_http_info(network_id, asset_id, opts)
      data
    end

    # Get the asset for the specified asset ID.
    # Get the asset for the specified asset ID.
    # @param network_id [String] The ID of the blockchain network
    # @param asset_id [String] The ID of the asset to fetch. This could be a symbol or an ERC20 contract address.
    # @param [Hash] opts the optional parameters
    # @return [Array<(Asset, Integer, Hash)>] Asset data, response status code and response headers
    def get_asset_with_http_info(network_id, asset_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: AssetsApi.get_asset ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling AssetsApi.get_asset"
      end
      # verify the required parameter 'asset_id' is set
      if @api_client.config.client_side_validation && asset_id.nil?
        fail ArgumentError, "Missing the required parameter 'asset_id' when calling AssetsApi.get_asset"
      end
      # resource path
      local_var_path = '/v1/networks/{network_id}/assets/{asset_id}'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'asset_id' + '}', CGI.escape(asset_id.to_s))

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
      return_type = opts[:debug_return_type] || 'Asset'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"AssetsApi.get_asset",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: AssetsApi#get_asset\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

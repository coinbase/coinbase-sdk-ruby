=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.5.0

=end

require 'cgi'

module Coinbase::Client
  class TransfersApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Create a new transfer for an address
    # Create a new transfer
    # @param wallet_id [String] The ID of the wallet the source address belongs to
    # @param address_id [String] The ID of the address to transfer from
    # @param create_transfer_request [CreateTransferRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Transfer]
    def create_transfer(wallet_id, address_id, create_transfer_request, opts = {})
      data, _status_code, _headers = create_transfer_with_http_info(wallet_id, address_id, create_transfer_request, opts)
      data
    end

    # Create a new transfer for an address
    # Create a new transfer
    # @param wallet_id [String] The ID of the wallet the source address belongs to
    # @param address_id [String] The ID of the address to transfer from
    # @param create_transfer_request [CreateTransferRequest] 
    # @param [Hash] opts the optional parameters
    # @return [Array<(Transfer, Integer, Hash)>] Transfer data, response status code and response headers
    def create_transfer_with_http_info(wallet_id, address_id, create_transfer_request, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: TransfersApi.create_transfer ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling TransfersApi.create_transfer"
      end
      # verify the required parameter 'address_id' is set
      if @api_client.config.client_side_validation && address_id.nil?
        fail ArgumentError, "Missing the required parameter 'address_id' when calling TransfersApi.create_transfer"
      end
      # verify the required parameter 'create_transfer_request' is set
      if @api_client.config.client_side_validation && create_transfer_request.nil?
        fail ArgumentError, "Missing the required parameter 'create_transfer_request' when calling TransfersApi.create_transfer"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/addresses/{address_id}/transfers'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s)).sub('{' + 'address_id' + '}', CGI.escape(address_id.to_s))

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(create_transfer_request)

      # return_type
      return_type = opts[:debug_return_type] || 'Transfer'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"TransfersApi.create_transfer",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: TransfersApi#create_transfer\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

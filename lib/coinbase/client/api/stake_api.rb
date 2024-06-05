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
  class StakeApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Build a new staking operation
    # Build a new staking operation
    # @param [Hash] opts the optional parameters
    # @option opts [BuildStakingOperationRequest] :build_staking_operation_request 
    # @return [StakingOperation]
    def build_staking_operation(opts = {})
      data, _status_code, _headers = build_staking_operation_with_http_info(opts)
      data
    end

    # Build a new staking operation
    # Build a new staking operation
    # @param [Hash] opts the optional parameters
    # @option opts [BuildStakingOperationRequest] :build_staking_operation_request 
    # @return [Array<(StakingOperation, Integer, Hash)>] StakingOperation data, response status code and response headers
    def build_staking_operation_with_http_info(opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: StakeApi.build_staking_operation ...'
      end
      # resource path
      local_var_path = '/v1/stake/build'

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'build_staking_operation_request'])

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
  end
end

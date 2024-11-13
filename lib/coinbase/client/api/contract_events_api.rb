=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.9.0

=end

require 'cgi'

module Coinbase::Client
  class ContractEventsApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # List contract events
    # Retrieve events for a specific contract
    # @param network_id [String] Unique identifier for the blockchain network
    # @param protocol_name [String] Case-sensitive name of the blockchain protocol
    # @param contract_address [String] EVM address of the smart contract (42 characters, including &#39;0x&#39;, in lowercase)
    # @param contract_name [String] Case-sensitive name of the specific contract within the project
    # @param event_name [String] Case-sensitive name of the event to filter for in the contract&#39;s logs
    # @param from_block_height [Integer] Lower bound of the block range to query (inclusive)
    # @param to_block_height [Integer] Upper bound of the block range to query (inclusive)
    # @param [Hash] opts the optional parameters
    # @option opts [String] :next_page Pagination token for retrieving the next set of results
    # @return [ContractEventList]
    def list_contract_events(network_id, protocol_name, contract_address, contract_name, event_name, from_block_height, to_block_height, opts = {})
      data, _status_code, _headers = list_contract_events_with_http_info(network_id, protocol_name, contract_address, contract_name, event_name, from_block_height, to_block_height, opts)
      data
    end

    # List contract events
    # Retrieve events for a specific contract
    # @param network_id [String] Unique identifier for the blockchain network
    # @param protocol_name [String] Case-sensitive name of the blockchain protocol
    # @param contract_address [String] EVM address of the smart contract (42 characters, including &#39;0x&#39;, in lowercase)
    # @param contract_name [String] Case-sensitive name of the specific contract within the project
    # @param event_name [String] Case-sensitive name of the event to filter for in the contract&#39;s logs
    # @param from_block_height [Integer] Lower bound of the block range to query (inclusive)
    # @param to_block_height [Integer] Upper bound of the block range to query (inclusive)
    # @param [Hash] opts the optional parameters
    # @option opts [String] :next_page Pagination token for retrieving the next set of results
    # @return [Array<(ContractEventList, Integer, Hash)>] ContractEventList data, response status code and response headers
    def list_contract_events_with_http_info(network_id, protocol_name, contract_address, contract_name, event_name, from_block_height, to_block_height, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ContractEventsApi.list_contract_events ...'
      end
      # verify the required parameter 'network_id' is set
      if @api_client.config.client_side_validation && network_id.nil?
        fail ArgumentError, "Missing the required parameter 'network_id' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'protocol_name' is set
      if @api_client.config.client_side_validation && protocol_name.nil?
        fail ArgumentError, "Missing the required parameter 'protocol_name' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'contract_address' is set
      if @api_client.config.client_side_validation && contract_address.nil?
        fail ArgumentError, "Missing the required parameter 'contract_address' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'contract_name' is set
      if @api_client.config.client_side_validation && contract_name.nil?
        fail ArgumentError, "Missing the required parameter 'contract_name' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'event_name' is set
      if @api_client.config.client_side_validation && event_name.nil?
        fail ArgumentError, "Missing the required parameter 'event_name' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'from_block_height' is set
      if @api_client.config.client_side_validation && from_block_height.nil?
        fail ArgumentError, "Missing the required parameter 'from_block_height' when calling ContractEventsApi.list_contract_events"
      end
      # verify the required parameter 'to_block_height' is set
      if @api_client.config.client_side_validation && to_block_height.nil?
        fail ArgumentError, "Missing the required parameter 'to_block_height' when calling ContractEventsApi.list_contract_events"
      end
      # resource path
      local_var_path = '/v1/networks/{network_id}/smart_contracts/{contract_address}/events'.sub('{' + 'network_id' + '}', CGI.escape(network_id.to_s)).sub('{' + 'contract_address' + '}', CGI.escape(contract_address.to_s))

      # query parameters
      query_params = opts[:query_params] || {}
      query_params[:'protocol_name'] = protocol_name
      query_params[:'contract_name'] = contract_name
      query_params[:'event_name'] = event_name
      query_params[:'from_block_height'] = from_block_height
      query_params[:'to_block_height'] = to_block_height
      query_params[:'next_page'] = opts[:'next_page'] if !opts[:'next_page'].nil?

      # header parameters
      header_params = opts[:header_params] || {}
      # HTTP header 'Accept' (if needed)
      header_params['Accept'] = @api_client.select_header_accept(['application/json']) unless header_params['Accept']

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type] || 'ContractEventList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"ContractEventsApi.list_contract_events",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ContractEventsApi#list_contract_events\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

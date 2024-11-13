=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.9.0

=end

require 'cgi'

module Coinbase::Client
  class WebhooksApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Create a new webhook scoped to a wallet
    # Create a new webhook scoped to a wallet
    # @param wallet_id [String] The ID of the wallet to create the webhook for.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWalletWebhookRequest] :create_wallet_webhook_request 
    # @return [Webhook]
    def create_wallet_webhook(wallet_id, opts = {})
      data, _status_code, _headers = create_wallet_webhook_with_http_info(wallet_id, opts)
      data
    end

    # Create a new webhook scoped to a wallet
    # Create a new webhook scoped to a wallet
    # @param wallet_id [String] The ID of the wallet to create the webhook for.
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWalletWebhookRequest] :create_wallet_webhook_request 
    # @return [Array<(Webhook, Integer, Hash)>] Webhook data, response status code and response headers
    def create_wallet_webhook_with_http_info(wallet_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WebhooksApi.create_wallet_webhook ...'
      end
      # verify the required parameter 'wallet_id' is set
      if @api_client.config.client_side_validation && wallet_id.nil?
        fail ArgumentError, "Missing the required parameter 'wallet_id' when calling WebhooksApi.create_wallet_webhook"
      end
      # resource path
      local_var_path = '/v1/wallets/{wallet_id}/webhooks'.sub('{' + 'wallet_id' + '}', CGI.escape(wallet_id.to_s))

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'create_wallet_webhook_request'])

      # return_type
      return_type = opts[:debug_return_type] || 'Webhook'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WebhooksApi.create_wallet_webhook",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WebhooksApi#create_wallet_webhook\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Create a new webhook
    # Create a new webhook
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWebhookRequest] :create_webhook_request 
    # @return [Webhook]
    def create_webhook(opts = {})
      data, _status_code, _headers = create_webhook_with_http_info(opts)
      data
    end

    # Create a new webhook
    # Create a new webhook
    # @param [Hash] opts the optional parameters
    # @option opts [CreateWebhookRequest] :create_webhook_request 
    # @return [Array<(Webhook, Integer, Hash)>] Webhook data, response status code and response headers
    def create_webhook_with_http_info(opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WebhooksApi.create_webhook ...'
      end
      # resource path
      local_var_path = '/v1/webhooks'

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'create_webhook_request'])

      # return_type
      return_type = opts[:debug_return_type] || 'Webhook'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WebhooksApi.create_webhook",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:POST, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WebhooksApi#create_webhook\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Delete a webhook
    # Delete a webhook
    # @param webhook_id [String] The Webhook uuid that needs to be deleted
    # @param [Hash] opts the optional parameters
    # @return [nil]
    def delete_webhook(webhook_id, opts = {})
      delete_webhook_with_http_info(webhook_id, opts)
      nil
    end

    # Delete a webhook
    # Delete a webhook
    # @param webhook_id [String] The Webhook uuid that needs to be deleted
    # @param [Hash] opts the optional parameters
    # @return [Array<(nil, Integer, Hash)>] nil, response status code and response headers
    def delete_webhook_with_http_info(webhook_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WebhooksApi.delete_webhook ...'
      end
      # verify the required parameter 'webhook_id' is set
      if @api_client.config.client_side_validation && webhook_id.nil?
        fail ArgumentError, "Missing the required parameter 'webhook_id' when calling WebhooksApi.delete_webhook"
      end
      # resource path
      local_var_path = '/v1/webhooks/{webhook_id}'.sub('{' + 'webhook_id' + '}', CGI.escape(webhook_id.to_s))

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
      return_type = opts[:debug_return_type]

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WebhooksApi.delete_webhook",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:DELETE, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WebhooksApi#delete_webhook\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # List webhooks
    # List webhooks, optionally filtered by event type.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [WebhookList]
    def list_webhooks(opts = {})
      data, _status_code, _headers = list_webhooks_with_http_info(opts)
      data
    end

    # List webhooks
    # List webhooks, optionally filtered by event type.
    # @param [Hash] opts the optional parameters
    # @option opts [Integer] :limit A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    # @option opts [String] :page A cursor for pagination across multiple pages of results. Don&#39;t include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    # @return [Array<(WebhookList, Integer, Hash)>] WebhookList data, response status code and response headers
    def list_webhooks_with_http_info(opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WebhooksApi.list_webhooks ...'
      end
      if @api_client.config.client_side_validation && !opts[:'page'].nil? && opts[:'page'].to_s.length > 5000
        fail ArgumentError, 'invalid value for "opts[:"page"]" when calling WebhooksApi.list_webhooks, the character length must be smaller than or equal to 5000.'
      end

      # resource path
      local_var_path = '/v1/webhooks'

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
      return_type = opts[:debug_return_type] || 'WebhookList'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WebhooksApi.list_webhooks",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:GET, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WebhooksApi#list_webhooks\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # Update a webhook
    # Update a webhook
    # @param webhook_id [String] The Webhook id that needs to be updated
    # @param [Hash] opts the optional parameters
    # @option opts [UpdateWebhookRequest] :update_webhook_request 
    # @return [Webhook]
    def update_webhook(webhook_id, opts = {})
      data, _status_code, _headers = update_webhook_with_http_info(webhook_id, opts)
      data
    end

    # Update a webhook
    # Update a webhook
    # @param webhook_id [String] The Webhook id that needs to be updated
    # @param [Hash] opts the optional parameters
    # @option opts [UpdateWebhookRequest] :update_webhook_request 
    # @return [Array<(Webhook, Integer, Hash)>] Webhook data, response status code and response headers
    def update_webhook_with_http_info(webhook_id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: WebhooksApi.update_webhook ...'
      end
      # verify the required parameter 'webhook_id' is set
      if @api_client.config.client_side_validation && webhook_id.nil?
        fail ArgumentError, "Missing the required parameter 'webhook_id' when calling WebhooksApi.update_webhook"
      end
      # resource path
      local_var_path = '/v1/webhooks/{webhook_id}'.sub('{' + 'webhook_id' + '}', CGI.escape(webhook_id.to_s))

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
      post_body = opts[:debug_body] || @api_client.object_to_http_body(opts[:'update_webhook_request'])

      # return_type
      return_type = opts[:debug_return_type] || 'Webhook'

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"WebhooksApi.update_webhook",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:PUT, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: WebhooksApi#update_webhook\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end

# frozen_string_literal: true

module Coinbase
  # A representation of a Webhook.
  class Webhook
    class << self
      # Creates a new Webhook on the specified Network and generate a default address for it.
      # @param network_id [String]  the ID of the blockchain network.
      # @return [Coinbase::Webhook] the new Webhook
      def create(network_id:, notification_uri:, event_type:, event_filters:)
        model = Coinbase.call_api do
          webhooks_api.create_webhook(
            create_webhook_request: {
              network_id: Coinbase.normalize_network(network_id),
              notification_uri: notification_uri,
              event_type: event_type,
              event_filters: event_filters
            }
          )
        end

        new(model)
      end

      def list_webhooks_page(page)
        webhooks_api.list_webhooks({ limit: DEFAULT_PAGE_LIMIT, page: page })
      end

      def update_webhook(webhook_id, network_id:, notification_uri:, event_type:, event_filters:)
        model = Coinbase.call_api do
          webhooks_api.update_webhook(
            webhook_id,
            update_webhook_request: {
              network_id: Coinbase.normalize_network(network_id),
              notification_uri: notification_uri,
              event_type: event_type,
              event_filters: event_filters
            }
          )
        end

        new(model)
      end

      def delete_webhook(webhook_id)
        model = Coinbase.call_api do
          webhooks_api.delete_webhook(
            webhook_id
          )
        end

        new(model)
      end
    end

    # Returns a new Wallet object. Do not use this method directly. Instead, use User#create_webhook
    # @param model [Coinbase::Client::Webhook] The underlying Webhook object
    def initialize(model)
      raise ArgumentError, 'model must be a Webhook' unless model.is_a?(Coinbase::Client::Webhook)

      @model = model
    end

    def webhooks_api
      Coinbase::Client::WebhooksApi.new(Coinbase.configuration.api_client)
    end
  end
end

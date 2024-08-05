# frozen_string_literal: true

module Coinbase
  # A representation of a Webhook.
  class Webhook
    class << self
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

      def list
        Coinbase::Pagination.enumerate(lambda(&method(:fetch_webhooks_page))) do |webhook|
          Coinbase::Webhook.new(webhook)
        end
      end

      private

      def webhooks_api
        @webhooks_api ||= Coinbase::Client::WebhooksApi.new(Coinbase.configuration.api_client)
      end

      def fetch_webhooks_page(page)
        webhooks_api.list_webhooks({ limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

    # Returns a new Webhook object.
    # @param model [Coinbase::Client::Webhook] The underlying Webhook object
    def initialize(model)
      raise ArgumentError, 'model must be a Webhook' unless model.is_a?(Coinbase::Client::Webhook)

      @webhook_id = model.id
      @model = model
    end

    def id
      @webhook_id
    end

    def update(network_id:, notification_uri:, event_type:, event_filters:)
      model = Coinbase.call_api do
        webhooks_api.update_webhook(
          id,
          update_webhook_request: {
            network_id: Coinbase.normalize_network(network_id),
            notification_uri: notification_uri,
            event_type: event_type,
            event_filters: event_filters
          }
        )
      end

      @model = model

      self
    end

    def delete
      Coinbase.call_api do
        webhooks_api.delete_webhook(
          id
        )
      end

      @model = nil

      self
    end
  end
end

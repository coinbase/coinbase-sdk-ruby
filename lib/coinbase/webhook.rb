# frozen_string_literal: true

module Coinbase
  # A representation of a Webhook.
  # This class provides methods to create, list, update, and delete webhooks
  # that are used to receive notifications of specific events.
  class Webhook
    class << self
      # Creates a new webhook for a specified network.
      #
      # @param network_id [String] The network ID for which the webhook is created.
      # @param notification_uri [String] The URI where notifications should be sent.
      # @param event_type [String] The type of event for the webhook (e.g., erc20_transfer).
      # @param event_filters [Array<Hash>] Filters applied to the events that determine
      #   which specific events trigger the webhook. Each filter should be a hash that
      #   can include keys like `contract_address`, `from_address`, or `to_address`.
      # @return [Coinbase::Webhook] A new instance of Webhook.
      #
      # @example Create a new webhook
      #   webhook = Coinbase::Webhook.create(
      #     network_id: 'ethereum',
      #     notification_uri: 'https://example.com/callback',
      #     event_type: 'transaction',
      #     event_filters: [{ 'contract_address' => '0x...', 'from_address' => '0x...', 'to_address' => '0x...' }]
      #   )
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

      # Enumerates the webhooks.
      # The result is an enumerator that lazily fetches from the server, and can be iterated over,
      # converted to an array, etc...
      # @return [Enumerable<Coinbase::Webhook>] Enumerator that returns webhooks
      def list
        Coinbase::Pagination.enumerate(lambda(&method(:fetch_webhooks_page))) do |webhook|
          Coinbase::Webhook.new(webhook)
        end
      end

      private

      def webhooks_api
        Coinbase::Client::WebhooksApi.new(Coinbase.configuration.api_client)
      end

      def fetch_webhooks_page(page)
        webhooks_api.list_webhooks({ limit: DEFAULT_PAGE_LIMIT, page: page })
      end
    end

    # Initializes a new Webhook object.
    #
    # @param model [Coinbase::Client::Webhook] The underlying Webhook object.
    # @raise [ArgumentError] If the model is not a Coinbase::Client::Webhook.
    def initialize(model)
      raise ArgumentError, 'model must be a Webhook' unless model.is_a?(Coinbase::Client::Webhook)

      @model = model
    end

    # Returns the ID of the webhook.
    #
    # @return [String] The ID of the webhook.
    def id
      @model.id
    end

    # Returns the network ID associated with the webhook.
    #
    # @return [String] The network ID of the webhook.
    def network_id
      @model.network_id
    end

    # Returns the notification URI of the webhook.
    #
    # @return [String] The URI where notifications are sent.
    def notification_uri
      @model.notification_uri
    end

    # Returns the event type of the webhook.
    #
    # @return [String] The type of event the webhook listens for.
    def event_type
      @model.event_type
    end

    # Returns the event filters applied to the webhook.
    #
    # @return [Array<Hash>] An array of event filters used by the webhook.
    def event_filters
      @model.event_filters
    end

    # Updates the webhook with a new notification URI.
    #
    # @param notification_uri [String] The new URI for webhook notifications.
    # @return [self] Returns the updated Webhook object.
    #
    # @example Update the notification URI of a webhook
    #   webhook.update(notification_uri: 'https://new-url.com/callback')
    def update(notification_uri:)
      serialized_event_filters = event_filters.map do |filter|
        {
          contract_address: filter['contract_address'],
          from_address: filter['from_address'],
          to_address: filter['to_address']
        }.compact
      end

      model = Coinbase.call_api do
        webhooks_api.update_webhook(
          id,
          update_webhook_request: {
            network_id: network_id,
            notification_uri: notification_uri,
            event_type: event_type,
            event_filters: serialized_event_filters
          }
        )
      end

      @model = model

      self
    end

    # Deletes the webhook.
    #
    # @return [self] Returns the Webhook object with nil attributes.
    #
    # @example Delete a webhook
    #   webhook.delete
    def delete
      Coinbase.call_api do
        webhooks_api.delete_webhook(
          id
        )
      end

      @model = nil

      self
    end

    private

    def webhooks_api
      @webhooks_api ||= Coinbase::Client::WebhooksApi.new(Coinbase.configuration.api_client)
    end
  end
end

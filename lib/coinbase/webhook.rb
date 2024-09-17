# frozen_string_literal: true

module Coinbase
  # A representation of a Webhook.
  # This class provides methods to create, list, update, and delete webhooks
  # that are used to receive notifications of specific events.
  class Webhook
    # Event type for ERC20 transfer
    ERC20_TRANSFER_EVENT = 'erc20_transfer'

    # Event type for ERC721 transfer
    ERC721_TRANSFER_EVENT = 'erc721_transfer'

    # Event type for Wallet activity
    WALLET_ACTIVITY_EVENT = 'wallet_activity'

    class << self
      # Creates a new webhook for a specified network.
      #
      # @param network_id [String] The network ID for which the webhook is created.
      # @param notification_uri [String] The URI where notifications should be sent.
      # @param event_type [String] The type of event for the webhook. Must be one of the following:
      #   - `Coinbase::Webhook::ERC20_TRANSFER_EVENT`
      #   - `Coinbase::Webhook::ERC721_TRANSFER_EVENT`
      # @param event_filters [Array<Hash>] Filters applied to the events that determine
      #   which specific events trigger the webhook. Each filter should be a hash that
      #   can include keys like `contract_address`, `from_address`, or `to_address`.
      # @param signature_header [String] The custom header to be used for x-webhook-signature header on callbacks,
      #   so developers can verify the requests are coming from Coinbase.
      # @param event_type_filter [Hash] Filters applied to wallet activity event type.
      # @return [Coinbase::Webhook] A new instance of Webhook.
      #
      # @example Create a new webhook
      #   webhook = Coinbase::Webhook.create(
      #     network_id: :ethereum_mainnet,
      #     notification_uri: 'https://example.com/callback',
      #     event_type: 'transaction',
      #     event_filters: [{ 'contract_address' => '0x...', 'from_address' => '0x...', 'to_address' => '0x...' }],
      #     signature_header: 'example_header',
      #     event_type_filter: {
      #       "addresses" => ["0xa3B299855BE3eA231337aC7c40A615e090A3de25"],
      #       "wallet_id" => "d91d652b-d020-48d4-bf19-5c5eb5e280c7"
      #     }
      #   )
      def create(
        network_id:,
        notification_uri:,
        event_type:,
        event_filters: [],
        signature_header: '',
        event_type_filter: nil
      )
        model = Coinbase.call_api do
          webhooks_api.create_webhook(
            create_webhook_request: {
              network_id: Coinbase.normalize_network(network_id),
              notification_uri: notification_uri,
              event_type: event_type,
              event_filters: event_filters,
              signature_header: signature_header,
              event_type_filter: event_type_filter
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
        Coinbase::Pagination.enumerate(method(:fetch_webhooks_page).to_proc) do |webhook|
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
    # @return [Symbol] The network ID of the webhook.
    def network_id
      Coinbase.to_sym(@model.network_id)
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
    # @return [Array<Coinbase::Client::WebhookEventFilter>] An array of event filters used by the webhook.
    def event_filters
      @model.event_filters
    end

    # Returns the signature header for the webhook. It is used as the value of callback header
    # with key 'x-webhook-signature'.
    #
    # @return [String] The signature header value.
    def signature_header
      @model.signature_header
    end

    # Returns the event type filters applied to the wallet activity webhook.
    #
    # @return [Array<Coinbase::Client::WebhookEventTypeFilter>] A hash of event type filter used by the webhook.
    def event_type_filter
      @model.event_type_filter
    end

    # Updates the webhook with a new notification URI.
    #
    # @param notification_uri [String] The new URI for webhook notifications.
    # @return [self] Returns the updated Webhook object.
    #
    # @example Update the notification URI of a webhook
    #   webhook.update(notification_uri: 'https://new-url.com/callback')
    def update(notification_uri:)
      model = Coinbase.call_api do
        webhooks_api.update_webhook(
          id,
          update_webhook_request: {
            notification_uri: notification_uri,
            event_filters: event_filters.map(&:to_hash)
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
        webhooks_api.delete_webhook(id)
      end

      @model = nil

      self
    end

    # Returns a String representation of the Webhook.
    # @return [String] a String representation of the Webhook
    def to_s
      Coinbase.pretty_print_object(
        self.class,
        id: @model.id,
        network_id: @model.network_id,
        event_type: @model.event_type,
        notification_uri: @model.notification_uri,
        event_filters: (@model.event_filters || []).map(&:to_hash).to_json,
        signature_header: @model.signature_header,
        event_type_filter: @model.event_type_filter
      )
    end

    # Same as to_s.
    # @return [String] a String representation of the Webhook
    def inspect
      to_s
    end

    private

    def webhooks_api
      @webhooks_api ||= Coinbase::Client::WebhooksApi.new(Coinbase.configuration.api_client)
    end
  end
end

# frozen_string_literal: true

describe Coinbase::Webhook do
  let(:api_client) { double('api_client') }
  let(:webhooks_api) { double('Coinbase::Client::WebhooksApi') }
  let(:webhook_model) do
    Coinbase::Client::Webhook.new(
      id: 'webhook_id',
      network_id: 'base-mainnet',
      event_type: 'erc20_transfer',
      event_filters: [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }],
      notification_uri: 'https://example.com/notify'
    )
  end

  before do
    allow(Coinbase.configuration).to receive(:api_client).and_return(api_client)
    allow(Coinbase::Client::WebhooksApi).to receive(:new).with(api_client).and_return(webhooks_api)
  end

  describe '.create' do
    let(:network_id) { 'base-mainnet' }
    let(:notification_uri) { 'https://example.com/notify' }
    let(:event_type) { 'erc20_transfer' }
    let(:event_filters) { [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }] }

    it 'creates a new webhook' do
      allow(webhooks_api).to receive(:create_webhook).and_return(webhook_model)
      expect(Coinbase).to receive(:call_api).and_yield

      webhook = Coinbase::Webhook.create(
        network_id: network_id,
        notification_uri: notification_uri,
        event_type: event_type,
        event_filters: event_filters
      )

      expect(webhook).to be_an_instance_of(Coinbase::Webhook)
      expect(webhook.id).to eq('webhook_id')
      expect(webhook.network_id).to eq(network_id)
      expect(webhook.notification_uri).to eq(notification_uri)
      expect(webhook.event_type).to eq(event_type)
      expect(webhook.event_filters).to eq(event_filters)
    end
  end

  describe '.list' do
    let(:api) { webhooks_api }
    let(:fetch_params) { ->(page) { [{ limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::WebhookList }
    let(:item_klass) { Coinbase::Webhook }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      Coinbase::Client::Webhook.new(
        id: 'webhook_id',
        network_id: 'base-mainnet',
        event_type: 'erc20_transfer',
        event_filters: [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }],
        notification_uri: 'https://example.com/notify'
      )
    end

    subject(:enumerator) do
      Coinbase::Webhook.list
    end

    it_behaves_like 'it is a paginated enumerator', :webhooks
  end

  describe '#initialize' do
    it 'raises an ArgumentError if model is not a Webhook' do
      expect { Coinbase::Webhook.new(Object.new) }.to raise_error(ArgumentError, 'model must be a Webhook')
    end

    it 'initializes with a valid webhook model' do
      webhook = Coinbase::Webhook.new(webhook_model)
      expect(webhook).to be_a(Coinbase::Webhook)
    end
  end

  describe '#update' do
    let(:new_notification_uri) { 'https://newurl.com/notify' }
    let(:updated_webhook_model) do
      Coinbase::Client::Webhook.new(
        id: 'webhook_id',
        network_id: 'base-mainnet',
        event_type: 'erc20_transfer',
        event_filters: [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }],
        notification_uri: new_notification_uri
      )
    end

    it 'updates the webhook' do
      allow(webhooks_api).to receive(:update_webhook).and_return(updated_webhook_model)

      webhook = Coinbase::Webhook.new(webhook_model)
      updated_webhook = webhook.update(notification_uri: new_notification_uri)

      expect(updated_webhook.notification_uri).to eq(new_notification_uri)
    end
  end

  describe '#delete' do
    it 'deletes the webhook' do
      webhook = Coinbase::Webhook.new(webhook_model)

      expect(webhooks_api).to receive(:delete_webhook).with(webhook.id)
      expect(Coinbase).to receive(:call_api).and_yield

      deleted_webhook = webhook.delete

      expect(deleted_webhook.instance_variable_get(:@model)).to be_nil
    end
  end
end

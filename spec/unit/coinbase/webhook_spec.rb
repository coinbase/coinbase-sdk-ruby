# frozen_string_literal: true

describe Coinbase::Webhook do
  let(:api_client) { instance_double(Coinbase::Client::ApiClient) }
  let(:webhooks_api) { instance_double(Coinbase::Client::WebhooksApi) }
  let(:webhook_model) { build(:webhook_model) }

  before do
    allow(Coinbase.configuration).to receive(:api_client).and_return(api_client)
    allow(Coinbase::Client::WebhooksApi).to receive(:new).with(api_client).and_return(webhooks_api)
  end

  describe '.create' do
    subject(:webhook) do
      described_class.create(
        network_id: network_id,
        notification_uri: notification_uri,
        event_type: event_type,
        event_filters: event_filters,
        event_type_filter: event_type_filter
      )
    end

    let(:network_id) { :base_sepolia }
    let(:notification_uri) { 'https://example.com/notify' }
    let(:event_type) { 'erc20_transfer' }
    let(:event_filters) { [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }] }
    let(:event_type_filter) do
      {
        'addresses' => ['0xa3B299855BE3eA231337aC7c40A615e090A3de25'],
        'wallet_id' => 'd91d652b-d020-48d4-bf19-5c5eb5e280c7'
      }
    end

    before do
      allow(webhooks_api).to receive(:create_webhook).and_return(webhook_model)
      allow(Coinbase).to receive(:call_api).and_yield
    end

    it 'creates a new webhook' do
      expect(webhook).to be_an_instance_of(described_class)
    end

    it 'has the correct id' do
      expect(webhook.id).to eq('webhook_id')
    end

    it 'has the correct network_id' do
      expect(webhook.network_id).to eq(network_id)
    end

    it 'has the correct notification_uri' do
      expect(webhook.notification_uri).to eq(notification_uri)
    end

    it 'has the correct event_type' do
      expect(webhook.event_type).to eq(event_type)
    end

    it 'has the correct event_filters' do
      expect(webhook.event_filters).to eq(event_filters)
    end

    it 'has the correct event_type_filter' do
      expect(webhook.event_type_filter).to eq(event_type_filter)
    end
  end

  describe '.list' do
    subject(:enumerator) { described_class.list }

    let(:api) { webhooks_api }
    let(:fetch_params) { ->(page) { [{ limit: 100, page: page }] } }
    let(:resource_list_klass) { Coinbase::Client::WebhookList }
    let(:item_klass) { described_class }
    let(:item_initialize_args) { nil }
    let(:create_model) do
      ->(id) { Coinbase::Client::Webhook.new(id: id, network_id: :base_sepolia) }
    end

    it_behaves_like 'it is a paginated enumerator', :webhooks
  end

  describe '#initialize' do
    it 'raises an ArgumentError if model is not a Webhook' do
      expect { described_class.new(Object.new) }.to raise_error(ArgumentError, 'model must be a Webhook')
    end

    it 'initializes with a valid webhook model' do
      webhook = described_class.new(webhook_model)
      expect(webhook).to be_a(described_class)
    end
  end

  describe '#update' do
    subject(:updated_webhook) { webhook.update(notification_uri: new_notification_uri) }

    let(:new_notification_uri) { 'https://newurl.com/notify' }
    let(:updated_webhook_model) { build(:webhook_model, :updated_uri, notification_uri: new_notification_uri) }
    let(:webhook) { described_class.new(webhook_model) }

    before do
      allow(webhooks_api).to receive(:update_webhook).and_return(updated_webhook_model)
    end

    it 'updates the webhook properties' do
      expect(updated_webhook.notification_uri).to eq(new_notification_uri)
    end

    it 'updates the webhook' do
      updated_webhook

      expect(webhooks_api).to have_received(:update_webhook).with(
        'webhook_id',
        update_webhook_request: {
          notification_uri: new_notification_uri,
          event_filters: [{ 'contract_address' => '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' }]
        }
      )
    end
  end

  describe '#delete' do
    subject(:deleted_webhook) { webhook.delete }

    let(:webhook) { described_class.new(webhook_model) }

    before do
      allow(webhooks_api).to receive(:delete_webhook)
    end

    it 'deletes the webhook' do
      deleted_webhook

      expect(webhooks_api).to have_received(:delete_webhook).with('webhook_id')
    end

    it 'unsets the model on the webhook' do
      expect(deleted_webhook.instance_variable_get(:@model)).to be_nil
    end
  end
end

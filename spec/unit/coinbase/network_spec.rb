# frozen_string_literal: true

describe Coinbase::Network do
  subject(:network) { described_class.new(network_id) }

  let(:networks_api) { instance_double(Coinbase::Client::NetworksApi) }
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:network_model) { build(:network_model, :ethereum_mainnet) }

  let(:eth) { build(:asset, network_id) }
  let(:usdc) { build(:asset, network_id, :usdc) }

  before do
    allow(Coinbase::Client::NetworksApi).to receive(:new).and_return(networks_api)
  end

  describe 'network constants' do
    Coinbase::Client::NetworkIdentifier.all_vars.each do |network_id|
      let(:network_const) { Coinbase.normalize_network(network_id).upcase }

      it "defines network constant for `#{network_id}`" do
        expect(described_class).to be_const_defined(:BASE_SEPOLIA)
      end
    end

    it 'defines the `ALL` constant' do
      expect(described_class).to be_const_defined(:ALL)
    end
  end

  describe '#initialize' do
    before { allow(networks_api).to receive(:get_network) }

    it 'initializes a network' do
      expect(network).to be_a(described_class)
    end

    it 'sets the network ID' do
      expect(network.id).to eq(network_id)
    end

    it 'does not fetch the network model' do
      network

      expect(networks_api).not_to have_received(:get_network)
    end
  end

  {
    chain_id: :chain_id,
    display_name: :display_name,
    testnet?: :is_testnet,
    protocol_family: :protocol_family
  }.each do |method, model_field|
    describe "##{method}" do
      before do
        allow(networks_api).to receive(:get_network).and_return(network_model)
      end

      it 'returns the value from the network model field' do
        expect(network.send(method)).to eq(network_model.send(model_field))
      end

      it 'fetches the network model' do
        network.send(method)

        expect(networks_api).to have_received(:get_network).with(normalized_network_id)
      end
    end
  end

  describe '#get_asset' do
    before do
      allow(Coinbase::Asset).to receive(:fetch).with(:ethereum_mainnet, :usdc).and_return(usdc)
    end

    it 'gets an asset by ID' do
      expect(network.get_asset(:usdc)).to eq(usdc)
    end
  end

  describe '#native_asset' do
    before do
      allow(networks_api).to receive(:get_network).and_return(network_model)
    end

    it 'returns the native asset of the network' do
      expect(network.native_asset.asset_id).to eq(eth.asset_id)
    end

    it 'fetches the network model' do
      network.native_asset

      expect(networks_api).to have_received(:get_network).with(normalized_network_id)
    end
  end
end

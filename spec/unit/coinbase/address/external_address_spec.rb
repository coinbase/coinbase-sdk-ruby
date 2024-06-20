# frozen_string_literal: true

describe Coinbase::ExternalAddress do
  let(:network_id) { :ethereum_mainnet }
  let(:normalized_network_id) { 'ethereum-mainnet' }
  let(:address_id) { '0x1234' }
  let(:external_addresses_api) { double('Coinbase::Client::ExternalAddressesApi') }
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'eth', decimals: 18)
  end
  let(:usdc_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'usdc', decimals: 6)
  end
  let(:weth_asset) do
    Coinbase::Client::Asset.new(network_id: normalized_network_id, asset_id: 'weth', decimals: 18)
  end

  subject(:address) { described_class.new(network_id, address_id) }

  before(:each) do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(Coinbase::ExternalAddress)
    end
  end

  describe '#network_id' do
    it 'returns the network ID' do
      expect(address.network_id).to eq(network_id)
    end
  end

  describe '#id' do
    it 'returns the address ID' do
      expect(address.id).to eq(address_id)
    end
  end

  describe '#balances' do
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        data: [
          Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset),
          Coinbase::Client::Balance.new(amount: '5000000000', asset: usdc_asset),
          Coinbase::Client::Balance.new(amount: '3000000000000000000', asset: weth_asset)
        ]
      )
    end

    before do
      allow(external_addresses_api)
        .to receive(:list_external_address_balances)
        .with(normalized_network_id, address_id)
        .and_return(response)
    end

    it 'returns a hash with balances' do
      expect(address.balances).to eq(
        eth: BigDecimal('1'),
        usdc: BigDecimal('5000'),
        weth: BigDecimal('3')
      )
    end

    it 'lists external address balances' do
      address.balances

      expect(external_addresses_api)
        .to have_received(:list_external_address_balances)
        .with(normalized_network_id, address_id)
    end
  end

  describe '#balance' do
    let(:response) do
      Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset)
    end

    before do
      allow(external_addresses_api)
        .to receive(:get_external_address_balance)
        .with(normalized_network_id, address_id, primary_denomination)
        .and_return(response)
    end

    context 'when the asset_id is :eth' do
      let(:asset_id) { :eth }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct ETH balance' do
        expect(address.balance(:eth)).to eq BigDecimal('1')
      end
    end

    context 'when the asset_id is :gwei' do
      let(:asset_id) { :gwei }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct Gwei balance' do
        expect(address.balance(:gwei)).to eq BigDecimal('1_000_000_000')
      end
    end

    context 'when the asset_id is :wei' do
      let(:asset_id) { :wei }
      let(:primary_denomination) { 'eth' }

      it 'returns the correct Wei balance' do
        expect(address.balance(:wei)).to eq BigDecimal('1_000_000_000_000_000_000')
      end
    end

    context 'when the asset id is a non-eth denomination' do
      let(:asset_id) { :other }
      let(:primary_denomination) { 'other' }
      let(:decimals) { 7 }
      let(:other_asset) do
        Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'other', decimals: decimals)
      end
      let(:response) do
        Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: other_asset)
      end

      it 'returns the correct balance' do
        expect(address.balance(:other)).to eq BigDecimal('100_000_000_000')
      end
    end

    context 'when there is no response' do
      let(:response) { nil }
      let(:asset_id) { :eth }
      let(:primary_denomination) { 'eth' }

      it 'returns 0' do
        expect(address.balance(:eth)).to eq BigDecimal('0')
      end
    end
  end

  describe '#faucet' do
    let(:request) { double('Request', transaction: transaction) }
    let(:tx_hash) { '0xdeadbeef' }
    let(:faucet_tx) do
      instance_double('Coinbase::Client::FaucetTransaction', transaction_hash: tx_hash)
    end

    context 'when the request is successful' do
      subject(:faucet_response) { address.faucet }

      before do
        expect(external_addresses_api)
          .to receive(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
          .and_return(faucet_tx)
      end

      it 'requests funds from the faucet and returns the faucet transaction' do
        expect(faucet_response).to be_a(Coinbase::FaucetTransaction)
        expect(faucet_response.transaction_hash).to eq(tx_hash)
      end
    end

    context 'when the request is unsuccesful' do
      before do
        expect(external_addresses_api)
          .to receive(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
          .and_raise(api_error)
      end

      context 'when the faucet limit is reached' do
        let(:api_error) do
          Coinbase::Client::ApiError.new(
            code: 429,
            response_body: {
              'code' => 'faucet_limit_reached',
              'message' => 'failed to claim funds - address likely has already claimed in the past 24 hours'
            }.to_json
          )
        end

        it 'raises a FaucetLimitReachedError' do
          expect { address.faucet }.to raise_error(::Coinbase::FaucetLimitReachedError)
        end
      end

      context 'when the request fails unexpectedly' do
        let(:api_error) do
          Coinbase::Client::ApiError.new(
            code: 500,
            response_body: {
              'code' => 'internal',
              'message' => 'unexpected error occurred while requesting faucet funds'
            }.to_json
          )
        end

        it 'raises an internal error' do
          expect { address.faucet }.to raise_error(::Coinbase::InternalError)
        end
      end
    end
  end
end

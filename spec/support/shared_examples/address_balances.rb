# frozen_string_literal: true

shared_examples 'an address that supports balance queries' do |_operation|
  let(:external_addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }

  before do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
  end

  describe '#balances' do
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        data: [
          build(:balance_model, amount: '1000000000000000000'),
          build(:balance_model, :usdc, amount: '5000000000'),
          build(:balance_model, :weth, amount: '3000000000000000000')
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
    let(:response) { build(:balance_model, amount: '1000000000000000000') }

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
      let(:other_asset) { build(:asset_model, asset_id: 'other', decimals: decimals) }
      let(:response) { build(:balance_model, asset: other_asset, amount: BigDecimal(10**18).to_s) }

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
end

shared_examples 'an address that supports requesting faucet funds' do |_operation|
  let(:external_addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }

  before do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
  end

  describe '#faucet' do
    let(:tx_hash) { '0xdeadbeef' }
    let(:faucet_tx) do
      instance_double(Coinbase::Client::FaucetTransaction, transaction_hash: tx_hash)
    end

    context 'when the request is successful' do
      subject(:faucet_response) { address.faucet }

      before do
        allow(external_addresses_api)
          .to receive(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
          .and_return(faucet_tx)
      end

      it 'requests external faucet funds for the address' do
        faucet_response

        expect(external_addresses_api)
          .to have_received(:request_external_faucet_funds)
          .with(normalized_network_id, address_id)
      end

      it 'returns the faucet transaction' do
        expect(faucet_response).to be_a(Coinbase::FaucetTransaction)
      end

      it 'returns the correct transaction hash' do
        expect(faucet_response.transaction_hash).to eq(tx_hash)
      end
    end

    context 'when the request is unsuccesful' do
      before do
        allow(external_addresses_api)
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
          expect { address.faucet }.to raise_error(Coinbase::FaucetLimitReachedError)
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
          expect { address.faucet }.to raise_error(Coinbase::InternalError)
        end
      end
    end
  end
end

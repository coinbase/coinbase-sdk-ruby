# frozen_string_literal: true

describe Coinbase::Address do
  let(:key) { Eth::Key.new }
  let(:private_key) { key.private_hex }
  let(:network_id) { :base_sepolia }
  let(:address_id) { key.address.to_s }
  let(:wallet_id) { SecureRandom.uuid }
  let(:model) do
    Coinbase::Client::Address.new(
      network_id: 'base-sepolia',
      address_id: address_id,
      wallet_id: wallet_id,
      public_key: key.public_key.compressed.unpack1('H*')
    )
  end
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
  end
  let(:usdc_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'usdc', decimals: 6)
  end
  let(:weth_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'weth', decimals: 18)
  end
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }
  let(:transfers_api) { double('Coinbase::Client::TransfersApi') }
  let(:client) { double('Jimson::Client') }

  before(:each) do
    allow(Coinbase.configuration).to receive(:base_sepolia_client).and_return(client)
    allow(Coinbase::Client::AddressesApi).to receive(:new).and_return(addresses_api)
    allow(Coinbase::Client::TransfersApi).to receive(:new).and_return(transfers_api)
  end

  subject(:address) do
    described_class.new(model, key)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(Coinbase::Address)
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

  describe '#wallet_id' do
    it 'returns the wallet ID' do
      expect(address.wallet_id).to eq(wallet_id)
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

    it 'returns a hash with balances' do
      expect(addresses_api)
        .to receive(:list_address_balances)
        .with(wallet_id, address_id)
        .and_return(response)

      expect(address.balances).to eq(
        eth: BigDecimal('1'),
        usdc: BigDecimal('5000'),
        weth: BigDecimal('3')
      )
    end
  end

  describe '#key=' do
    let(:unhydrated_address) { described_class.new(model, nil) }

    it 'sets the key' do
      expect { unhydrated_address.key = key }.not_to raise_error
    end

    it 'raises an error if the key is already set' do
      expect { address.key = key }.to raise_error('Private key is already set')
    end
  end

  describe '#balance' do
    let(:response) do
      Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset)
    end

    it 'returns the correct ETH balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.balance(:eth)).to eq BigDecimal('1')
    end

    it 'returns the correct Gwei balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.balance(:gwei)).to eq BigDecimal('1_000_000_000')
    end

    it 'returns the correct Wei balance' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'eth')
        .and_return(response)
      expect(address.balance(:wei)).to eq BigDecimal('1_000_000_000_000_000_000')
    end

    it 'returns 0 for an unsupported asset' do
      expect(addresses_api)
        .to receive(:get_address_balance)
        .with(wallet_id, address_id, 'uni')
        .and_return(nil)
      expect(address.balance(:uni)).to eq BigDecimal('0')
    end
  end

  describe '#transfer' do
    let(:eth_balance_response) do
      Coinbase::Client::Balance.new(amount: '1000000000000000000', asset: eth_asset)
    end
    let(:usdc_balance_response) do
      Coinbase::Client::Balance.new(amount: '10000000000', asset: usdc_asset)
    end
    let(:transfer_id) { SecureRandom.uuid }
    let(:to_key) { Eth::Key.new }
    let(:to_address_id) { to_key.address.to_s }
    let(:transaction_hash) { '0xdeadbeef' }
    let(:raw_signed_transaction) { '0123456789abcdef' }
    let(:signed_payload) { '0x12345' }
    let(:broadcast_transfer_request) do
      { signed_payload: raw_signed_transaction }
    end
    let(:transaction) { double('Transaction', sign: transaction_hash, hex: raw_signed_transaction) }
    let(:created_transfer) { double('Transfer', transaction: transaction, id: transfer_id) }
    let(:transfer_model) { instance_double('Coinbase::Client::Transfer', status: 'pending') }
    let(:broadcasted_transfer_model) { instance_double('Coinbase::Client::Transfer', status: 'broadcast') }
    let(:broadcasted_transfer) { double('Transfer', transaction: transaction, id: transfer_id) }
    let(:transfer_asset_id) { 'eth' }
    let(:balance_response) { eth_balance_response }
    let(:destination) { to_address_id }

    subject(:transfer) { address.transfer(amount, asset_id, destination) }

    context 'when the transfer is successful' do
      let(:asset_id) { :wei }
      let(:amount) { 500_000_000_000_000_000 }
      let(:transfer_amount) { 500_000_000_000_000_000 }
      let(:create_transfer_request) do
        { amount: transfer_amount.to_s, network_id: network_id, asset_id: transfer_asset_id,
          destination: to_address_id }
      end

      before do
        allow(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, transfer_asset_id)
          .and_return(balance_response)

        allow(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
          .and_return(transfer_model)

        allow(Coinbase::Transfer).to receive(:new).with(transfer_model).and_return(created_transfer)

        allow(transfers_api)
          .to receive(:broadcast_transfer)
          .with(wallet_id, address_id, transfer_id, broadcast_transfer_request)
          .and_return(broadcasted_transfer_model)

        allow(Coinbase::Transfer).to receive(:new).with(broadcasted_transfer_model).and_return(broadcasted_transfer)

        transfer
      end

      it 'creates the transfer' do
        expect(transfers_api)
          .to have_received(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
      end

      it 'returns the broadcasted transfer' do
        expect(transfer).to eq(broadcasted_transfer)
      end

      it 'signs the transaction with the key' do
        expect(transaction).to have_received(:sign).with(key)
      end

      context 'when the asset is Gwei' do
        let(:asset_id) { :gwei }
        let(:amount) { 500_000_000 }

        it 'returns the broadcast transfer' do
          expect(transfer).to eq(broadcasted_transfer)
        end

        it 'signs the transaction with the address key' do
          expect(transaction).to have_received(:sign).with(key)
        end
      end

      context 'when the asset is ETH' do
        let(:asset_id) { :eth }
        let(:amount) { 0.5 }
        let(:transfer_amount) { 500_000_000_000_000_000 }

        it 'returns the broadcast transfer' do
          expect(transfer).to eq(broadcasted_transfer)
        end

        it 'signs the transaction with the address key' do
          expect(transaction).to have_received(:sign).with(key)
        end
      end

      context 'when the asset is USDC' do
        let(:asset_id) { :usdc }
        let(:transfer_asset_id) { 'usdc' }
        let(:amount) { 5 }
        let(:transfer_amount) { 5_000_000 }
        let(:balance_response) { usdc_balance_response }

        it 'creates a Transfer' do
          expect(transfer).to eq(broadcasted_transfer)
        end
      end

      context 'when the destination is a Wallet' do
        let(:default_address_model) do
          Coinbase::Client::Address.new(
            network_id: 'base-sepolia',
            address_id: to_address_id,
            wallet_id: wallet_id,
            public_key: to_key.public_key.compressed.unpack1('H*')
          )
        end
        let(:destination) do
          Coinbase::Wallet.new(
            Coinbase::Client::Wallet.new(id: wallet_id, network_id: 'base-sepolia',
                                         default_address: default_address_model),
            seed: '',
            address_models: [default_address_model]
          )
        end

        it 'returns the broadcasted transfer' do
          expect(transfer).to eq(broadcasted_transfer)
        end

        it 'signs the transaction with the address key' do
          expect(transaction).to have_received(:sign).with(key)
        end
      end

      context 'when the destination is a Address' do
        let(:asset_id) { :wei }
        let(:amount) { 500_000_000_000_000_000 }
        let(:transfer_amount) { amount }
        let(:balance_response) { eth_balance_response }
        let(:to_model) do
          Coinbase::Client::Address.new(
            network_id: 'base-sepolia',
            address_id: to_address_id,
            wallet_id: wallet_id,
            public_key: to_key.public_key.compressed.unpack1('H*')
          )
        end
        let(:destination) { described_class.new(to_model, to_key) }
        let(:destination_address) { destination.id }

        it 'returns the broadcasted transfer' do
          expect(transfer).to eq(broadcasted_transfer)
        end

        it 'signs the transaction with the address key' do
          expect(transaction).to have_received(:sign).with(key)
        end
      end
    end

    context 'when the destination Address is on a different network' do
      let(:to_model) do
        Coinbase::Client::Address.new(
          network_id: 'ethereum-sepolia',
          address_id: to_address_id,
          wallet_id: wallet_id,
          public_key: to_key.public_key.compressed.unpack1('H*')
        )
      end
      let(:amount) { 500_000_000_000_000_000 }
      let(:asset_id) { :wei }
      let(:destination) { described_class.new(to_model, to_key) }

      it 'raises an ArgumentError' do
        expect do
          address.transfer(amount, asset_id, destination)
        end.to raise_error(ArgumentError, 'Transfer must be on the same Network')
      end
    end

    context 'when the destination Wallet is on a different network' do
      let(:default_address_model) do
        Coinbase::Client::Address.new(
          network_id: 'base-sepolia',
          address_id: to_address_id,
          wallet_id: wallet_id,
          public_key: to_key.public_key.compressed.unpack1('H*')
        )
      end
      let(:destination) do
        Coinbase::Wallet.new(
          Coinbase::Client::Wallet.new(id: wallet_id, network_id: 'base-mainnet',
                                       default_address: default_address_model),
          seed: '',
          address_models: [default_address_model]
        )
      end

      let(:amount) { 500_000_000_000_000_000 }
      let(:asset_id) { :wei }

      it 'raises an ArgumentError' do
        expect do
          address.transfer(amount, asset_id, destination)
        end.to raise_error(ArgumentError, 'Transfer must be on the same Network')
      end
    end

    context 'when the asset is unsupported' do
      let(:amount) { 500_000_000_000_000_000 }
      let(:transfer_amount) { amount }
      let(:asset_id) { :uni }

      it 'raises an ArgumentError' do
        expect do
          address.transfer(amount, asset_id, destination)
        end.to raise_error(ArgumentError, 'Unsupported asset: uni')
      end
    end

    context 'when the balance is insufficient' do
      let(:asset_id) { :wei }
      let(:excessive_amount) { 9_000_000_000_000_000_000_000 }
      let(:excessive_amount) { 9_000_000_000_000_000_000_000 }

      before do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
      end

      it 'raises an ArgumentError' do
        expect do
          address.transfer(excessive_amount, asset_id, to_address_id)
        end.to raise_error(ArgumentError)
      end
    end

    context 'when the Address is unhydrated' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an error' do
        expect do
          unhydrated_address.transfer(1, :wei, to_address_id)
        end.to raise_error('Cannot transfer from address without private key loaded')
      end
    end

    context 'when using server signer' do
      let(:configuration) { double('Coinbase::Configuration', use_server_signer: true, api_client: nil) }
      let(:asset_id) { :wei }
      let(:amount) { 500_000_000_000_000_000 }
      let(:destination) { described_class.new(model, to_key) }
      let(:create_transfer_request) do
        { amount: amount.to_s, network_id: network_id, asset_id: 'eth', destination: destination.id }
      end

      before do
        allow(Coinbase).to receive(:configuration).and_return(configuration)
        allow(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, transfer_asset_id)
          .and_return(balance_response)

        allow(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
          .and_return(transfer_model)
        allow(Coinbase::Transfer).to receive(:new).with(transfer_model).and_return(created_transfer)
      end

      it 'creates a transfer without broadcast' do
        expect(addresses_api)
          .to receive(:get_address_balance)
          .with(wallet_id, address_id, 'eth')
          .and_return(eth_balance_response)
        expect(transfers_api)
          .to receive(:create_transfer)
          .with(wallet_id, address_id, create_transfer_request)
        expect(address.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end
  end

  describe '#can_sign?' do
    it 'returns true if the address has a key' do
      expect(address.can_sign?).to be true
    end

    it 'returns false if the address does not have a key' do
      unhydrated_address = described_class.new(model, nil)
      expect(unhydrated_address.can_sign?).to be false
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
        expect(addresses_api)
          .to receive(:request_faucet_funds)
          .with(wallet_id, address_id)
          .and_return(faucet_tx)
      end

      it 'requests funds from the faucet and returns the faucet transaction' do
        expect(faucet_response).to be_a(Coinbase::FaucetTransaction)
        expect(faucet_response.transaction_hash).to eq(tx_hash)
      end
    end

    context 'when the request is unsuccesful' do
      before do
        expect(addresses_api)
          .to receive(:request_faucet_funds)
          .with(wallet_id, address_id)
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

  describe '#export' do
    it 'export private key from address' do
      expect(address.export).to eq(private_key)
    end

    context 'when the address is unhydrated' do
      let(:unhydrated_address) { described_class.new(model, nil) }

      it 'raises an error' do
        expect do
          unhydrated_address.export
        end.to raise_error('Cannot export key without private key loaded')
      end
    end
  end

  describe '#transfers' do
    let(:page_size) { 6 }
    let(:transfer_ids) do
      Array.new(page_size) { SecureRandom.uuid }
    end
    let(:data) do
      transfer_ids.map { |id| Coinbase::Client::Transfer.new(transfer_id: id, network_id: 'base-sepolia') }
    end
    let(:transfers_list) { Coinbase::Client::TransferList.new(data: data) }
    let(:expected_transfers) do
      data.map { |transfer_model| Coinbase::Transfer.new(transfer_model) }
    end

    before do
      data.each_with_index do |transfer_model, i|
        allow(Coinbase::Transfer).to receive(:new).with(transfer_model).and_return(expected_transfers[i])
      end
    end

    it 'lists the transfers' do
      expect(transfers_api)
        .to receive(:list_transfers)
        .with(wallet_id, address_id, { limit: 100, page: nil })
        .and_return(transfers_list)

      expect(address.transfers).to eq(expected_transfers)
    end

    context 'with no transfers' do
      let(:data) { [] }

      it 'returns an empty list' do
        expect(transfers_api)
          .to receive(:list_transfers)
          .with(wallet_id, address_id, { limit: 100, page: nil })
          .and_return(transfers_list)

        expect(address.transfers).to be_empty
      end
    end

    context 'with multiple pages' do
      let(:page_size) { 150 }
      let(:next_page) { 'page_token_2' }
      let(:transfers_list_page1) do
        Coinbase::Client::TransferList.new(data: data.take(100), has_more: true, next_page: next_page)
      end
      let(:transfers_list_page2) do
        Coinbase::Client::TransferList.new(data: data.drop(100), has_more: false, next_page: nil)
      end

      it 'lists all of the transfers' do
        expect(transfers_api)
          .to receive(:list_transfers)
          .with(wallet_id, address_id, { limit: 100, page: nil })
          .and_return(transfers_list_page1)

        expect(transfers_api)
          .to receive(:list_transfers)
          .with(wallet_id, address_id, { limit: 100, page: next_page })
          .and_return(transfers_list_page2)

        expect(address.transfers).to eq(expected_transfers)
      end
    end
  end

  describe '#inspect' do
    it 'includes address details' do
      expect(address.inspect).to include(address_id, Coinbase.to_sym(network_id).to_s, wallet_id)
    end

    it 'returns the same value as to_s' do
      expect(address.inspect).to eq(address.to_s)
    end
  end
end

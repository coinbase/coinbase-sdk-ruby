# frozen_string_literal: true

describe Coinbase::Wallet do
  let(:client) { double('Jimson::Client') }
  let(:wallet_id) { SecureRandom.uuid }
  let(:model) { Coinbase::Client::Wallet.new({ 'id': wallet_id, 'network_id': 'base-sepolia' }) }
  let(:address_model) do
    Coinbase::Client::Address.new({
                                    'address_id': '0xdeadbeef',
                                    'wallet_id': wallet_id,
                                    'public_key': '0x1234567890',
                                    'network_id': 'base-sepolia'
                                  })
  end
  let(:model_with_default_address) do
    Coinbase::Client::Wallet.new(
      {
        'id': wallet_id,
        'network_id': 'base-sepolia',
        'default_address': address_model
      }
    )
  end
  let(:wallets_api) { double('Coinbase::Client::WalletsApi') }
  let(:addresses_api) { double('Coinbase::Client::AddressesApi') }

  before do
    allow(addresses_api).to receive(:create_address).and_return(address_model)
    allow(addresses_api).to receive(:get_address).and_return(address_model)
    allow(wallets_api).to receive(:get_wallet).with(wallet_id).and_return(model_with_default_address)
    @wallet = described_class.new(model, wallets_api, addresses_api, client: client)
  end

  describe '#initialize' do
    context 'when no seed or address count is provided' do
      it 'initializes a new Wallet' do
        expect(addresses_api)
          .to receive(:create_address)
          .with(wallet_id, satisfy do |opts|
            public_key_present = opts[:create_address_request][:public_key].is_a?(String)
            attestation_present = opts[:create_address_request][:attestation].is_a?(String)
            public_key_present && attestation_present
          end)
        @wallet = described_class.new(model, wallets_api, addresses_api, client: client)
        expect(@wallet).to be_a(Coinbase::Wallet)
      end
    end

    context 'when a seed is provided' do
      let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
      let(:seed_wallet) { described_class.new(model, wallets_api, addresses_api, seed: seed, client: client) }

      it 'initializes a new Wallet with the provided seed' do
        expect(addresses_api)
          .to receive(:create_address)
          .with(wallet_id, satisfy do |opts|
            public_key_present = opts[:create_address_request][:public_key].is_a?(String)
            attestation_present = opts[:create_address_request][:attestation].is_a?(String)
            public_key_present && attestation_present
          end)
          .and_return(address_model)
        expect(seed_wallet).to be_a(Coinbase::Wallet)
      end

      it 'raises an error for an invalid seed' do
        expect do
          described_class.new(model, wallets_api, addresses_api, seed: 'invalid', client: client)
        end.to raise_error(ArgumentError, 'Seed must be 32 bytes')
      end
    end

    context 'when the address count is provided' do
      let(:address_count) { 5 }
      let(:address_wallet) do
        described_class.new(model, wallets_api, addresses_api, address_count: address_count, client: client)
      end

      it 'initializes a new Wallet with the provided address count' do
        expect(addresses_api).to receive(:get_address).exactly(address_count).times
        expect(address_wallet.list_addresses.length).to eq(address_count)
      end
    end
  end

  describe '#wallet_id' do
    it 'returns the Wallet ID' do
      expect(@wallet.wallet_id).to eq(wallet_id)
    end
  end

  describe '#network_id' do
    it 'returns the Network ID' do
      expect(@wallet.network_id).to eq(:base_sepolia)
    end
  end

  describe '#create_address' do
    it 'creates a new address' do
      expect(addresses_api)
        .to receive(:create_address)
        .with(wallet_id, satisfy do |opts|
          public_key_present = opts[:create_address_request][:public_key].is_a?(String)
          attestation_present = opts[:create_address_request][:attestation].is_a?(String)
          public_key_present && attestation_present
        end)
        .and_return(address_model)
        .exactly(1).times
      address = @wallet.create_address
      expect(address).to be_a(Coinbase::Address)
      expect(@wallet.list_addresses.length).to eq(2)
      expect(address).not_to eq(@wallet.default_address)
    end
  end

  describe '#default_address' do
    it 'returns the first address' do
      expect(@wallet.default_address).to eq(@wallet.list_addresses.first)
    end
  end

  describe '#get_address' do
    before do
      allow(addresses_api).to receive(:create_address).and_return(address_model)
    end

    it 'returns the correct address' do
      default_address = @wallet.default_address
      expect(@wallet.get_address(default_address.address_id)).to eq(default_address)
    end
  end

  describe '#list_addresses' do
    it 'contains one address' do
      expect(@wallet.list_addresses.length).to eq(1)
    end
  end

  describe '#list_balances' do
    let(:response) do
      Coinbase::Client::AddressBalanceList.new(
        'data' => [
          Coinbase::Client::Balance.new(
            {
              'amount' => '1000000000000000000',
              'asset' => Coinbase::Client::Asset.new({
                                                       'network_id': 'base-sepolia',
                                                       'asset_id': 'eth',
                                                       'decimals': 18
                                                     })
            }
          ),
          Coinbase::Client::Balance.new(
            {
              'amount' => '5000',
              'asset' => Coinbase::Client::Asset.new({
                                                       'network_id': 'base-sepolia',
                                                       'asset_id': 'usdc',
                                                       'decimals': 6
                                                     })
            }
          )
        ]
      )
    end
    before do
      expect(wallets_api).to receive(:list_wallet_balances).and_return(response)
    end

    it 'returns a hash with an ETH balance' do
      expect(@wallet.list_balances).to eq({ eth: BigDecimal(1), usdc: BigDecimal(5000) })
    end
  end

  describe '#get_balance' do
    let(:response) do
      Coinbase::Client::Balance.new(
        {
          'amount' => '5000000000000000000',
          'asset' => Coinbase::Client::Asset.new({
                                                   'network_id': 'base-sepolia',
                                                   'asset_id': 'eth',
                                                   'decimals': 18
                                                 })
        }
      )
    end

    before do
      expect(wallets_api).to receive(:get_wallet_balance).with(wallet_id, 'eth').and_return(response)
    end

    it 'returns the correct ETH balance' do
      expect(@wallet.get_balance(:eth)).to eq(BigDecimal(5))
    end

    it 'returns the correct Gwei balance' do
      expect(@wallet.get_balance(:gwei)).to eq(BigDecimal(5 * Coinbase::GWEI_PER_ETHER))
    end

    it 'returns the correct Wei balance' do
      expect(@wallet.get_balance(:wei)).to eq(BigDecimal(5 * Coinbase::WEI_PER_ETHER))
    end
  end

  describe '#transfer' do
    let(:transfer) { double('Coinbase::Transfer') }
    let(:amount) { 5 }
    let(:asset_id) { :eth }

    context 'when the destination is a Wallet' do
      let(:destination) { described_class.new(model, wallets_api, addresses_api, client: client) }
      let(:to_address_id) { destination.default_address.address_id }

      before do
        expect(@wallet.default_address).to receive(:transfer).with(amount, asset_id, to_address_id).and_return(transfer)
      end

      it 'creates a transfer to the default address ID' do
        expect(@wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the desination is an Address' do
      let(:destination) { @wallet.create_address }
      let(:to_address_id) { destination.address_id }

      before do
        expect(@wallet.default_address).to receive(:transfer).with(amount, asset_id, to_address_id).and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(@wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end

    context 'when the destination is a String' do
      let(:destination) { '0x1234567890' }

      before do
        expect(@wallet.default_address).to receive(:transfer).with(amount, asset_id, destination).and_return(transfer)
      end

      it 'creates a transfer to the address ID' do
        expect(@wallet.transfer(amount, asset_id, destination)).to eq(transfer)
      end
    end
  end

  describe '#export' do
    let(:seed) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    let(:address_count) { 5 }
    let(:seed_wallet) do
      described_class.new(model, wallets_api, addresses_api, seed: seed, address_count: address_count, client: client)
    end

    it 'exports the Wallet data' do
      wallet_data = seed_wallet.export
      expect(wallet_data).to be_a(Coinbase::Wallet::Data)
      expect(wallet_data.wallet_id).to eq(seed_wallet.wallet_id)
      expect(wallet_data.seed).to eq(seed)
    end

    it 'allows for re-creation of a Wallet' do
      wallet_data = seed_wallet.export
      new_wallet = described_class.new(model, wallets_api, addresses_api, seed: wallet_data.seed,
                                                                          address_count: address_count, client: client)
      expect(new_wallet.list_addresses.length).to eq(address_count)
      new_wallet.list_addresses.each_with_index do |address, i|
        expect(address.address_id).to eq(seed_wallet.list_addresses[i].address_id)
      end
    end
  end
end

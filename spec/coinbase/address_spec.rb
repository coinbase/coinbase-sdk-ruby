# frozen_string_literal: true

describe Coinbase::Address do
  let(:address_id) { '0xd8ddbFD00B958E94a024FB8C116AE89C70c60257' }
  let(:api_key_file) { 'spec/fixtures/coinbase_cloud_api_key.json' }

  subject(:address) do
    # TODO: Pass a legitimate private key.
    described_class.new(:base_sepolia, address_id, SecureRandom.uuid, nil)
  end

  before do
    Coinbase.init_json(api_key_file)
  end

  describe '#initialize' do
    it 'initializes a new Address' do
      expect(address).to be_a(Coinbase::Address)
    end
  end

  describe '#address_id' do
    it 'returns the address ID' do
      expect(address.address_id).to eq(address_id)
    end
  end

  describe '#list_balances' do
    it 'returns a hash with an ETH balance' do
      expect(address.list_balances[:eth]).to be > 0
    end
  end

  describe '#get_balance' do
    it 'returns the ETH balance' do
      expect(address.get_balance(:eth)).to be > 0
    end
  end

  describe '#to_s' do
    it 'returns the address as a string' do
      expect(address.to_s).to eq(address_id)
    end
  end
end

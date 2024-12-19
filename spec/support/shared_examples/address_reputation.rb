# frozen_string_literal: true

shared_examples 'an address that supports reputation' do
  let(:score) { 50 }
  let(:metadata) { { total_transactions: 10, unique_days_active: 42 } }
  let(:address_reputation) { build(:address_reputation, score: score, metadata: metadata) }

  before do
    allow(Coinbase::AddressReputation).to receive(:fetch).and_return(address_reputation)
  end

  it 'fetches the address reputation from the API' do
    expect(address.reputation).to be_a(Coinbase::AddressReputation)
  end

  it 'returns the reputation score' do
    expect(address_reputation.score).to eq(score)
  end

  it 'returns metadata as a Metadata object' do
    expect(address_reputation.metadata).to be_a(Coinbase::AddressReputation::Metadata)
  end

  it 'has correct metadata values for total transactions' do
    expect(address_reputation.metadata.total_transactions).to eq(metadata[:total_transactions])
  end

  it 'has correct metadata values for unique days active' do
    expect(address_reputation.metadata.unique_days_active).to eq(metadata[:unique_days_active])
  end
end

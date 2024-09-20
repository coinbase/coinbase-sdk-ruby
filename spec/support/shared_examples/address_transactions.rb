# frozen_string_literal: true

shared_examples 'an address that supports transaction queries' do |_operation|
  let(:external_addresses_api) { instance_double(Coinbase::Client::ExternalAddressesApi) }
  let(:transaction_history_api) { instance_double(Coinbase::Client::TransactionHistoryApi) }

  before do
    allow(Coinbase::Client::ExternalAddressesApi).to receive(:new).and_return(external_addresses_api)
  end

  describe '#transactions' do
    let(:transaction) { build(:transaction_model, :indexed) }
    let(:response) do
      Coinbase::Client::AddressTransactionList.new(
        data: [
          transaction
        ]
      )
    end

    before do
      allow(transaction_history_api)
        .to receive(:list_address_transactions)
        .with(normalized_network_id, address_id, { limit: 10, page: nil })
        .and_return(response)
    end

    context 'when list transactions' do
      it 'returns the correct transactions' do
        expect(address.transactions.first.block_height).to eq '123'
      end
    end

    context 'when using enumerator of transactions' do
      subject(:enumerator) do
        address.transactions
      end

      let(:api) { external_addresses_api }
      let(:fetch_params) { ->(page) { [normalized_network_id, address_id, { limit: 10, page: page }] } }
      let(:resource_list_klass) { Coinbase::Client::AddressTransactionList }
      let(:item_klass) { Coinbase::Transaction }
      let(:item_initialize_args) { nil }
      let(:create_model) do
        ->(id) { build(:transaction_model, transaction_hash: id) }
      end

      it_behaves_like 'it is a paginated enumerator', :address_transactions
    end
  end
end

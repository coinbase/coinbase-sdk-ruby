# frozen_string_literal: true

describe Coinbase do
  let(:api_key_file) { 'spec/fixtures/coinbase_cloud_api_key.json' }

  describe '#init_json' do
    it 'correctly parses the API Key JSON file' do
      Coinbase.init_json(api_key_file)
      expect(Coinbase.api_key_name).not_to be_empty
      expect(Coinbase.api_key_secret).not_to be_empty
    end
  end
end

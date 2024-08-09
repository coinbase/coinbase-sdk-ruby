# frozen_string_literal: true

describe Coinbase::APIError do
  describe '#from_error' do
    subject(:api_error) { described_class.from_error(err) }

    context 'when the error has a recognized API error code' do
      let(:http_code) { 400 }
      let(:api_code) { 'unsupported_asset' }
      let(:api_message) { 'Asset "test" is not supported on "base-sepolia"' }
      let(:err) do
        Coinbase::Client::ApiError.new(
          code: http_code,
          response_body: { code: api_code, message: api_message }.to_json
        )
      end

      it 'returns an instance of the appropriate error class' do
        expect(api_error).to be_a(Coinbase::UnsupportedAssetError)
      end

      it 'sets the http_code attribute' do
        expect(api_error.http_code).to eq(http_code)
      end

      it 'sets the api code' do
        expect(api_error.api_code).to eq(api_code)
      end

      it 'sets the api message' do
        expect(api_error.api_message).to eq(api_message)
      end

      it 'sets the error message to the api message' do
        expect(api_error.message).to eq(api_message)
      end
    end

    context 'when the error is a generic error' do
      let(:err) { StandardError.new('message') }

      it 'raises an ArgumentError' do
        expect { described_class.from_error(err) }.to raise_error(ArgumentError)
      end
    end

    context 'when the error is an ApiError without a response body' do
      let(:http_code) { 501 }
      let(:err) { Coinbase::Client::ApiError.new(code: http_code) }

      it 'returns an instance of Coinbase::APIError' do
        expect(api_error).to be_a(described_class)
      end

      it 'sets the http_code attribute' do
        expect(api_error.http_code).to eq(http_code)
      end

      it 'does not set the api code' do
        expect(api_error.api_code).to be_nil
      end

      it 'does not set the api message' do
        expect(api_error.api_message).to be_nil
      end

      it 'sets the error message to the default error message' do
        expect(api_error.message).to eq(err.message)
      end
    end

    context 'when the error response body is not valid JSON' do
      let(:http_code) { 501 }
      let(:err) do
        Coinbase::Client::ApiError.new(code: http_code, response_body: 'invalid json')
      end

      it 'returns an instance of Coinbase::APIError' do
        expect(api_error).to be_a(described_class)
      end

      it 'sets the http_code attribute' do
        expect(api_error.http_code).to eq(http_code)
      end

      it 'does not set the api code' do
        expect(api_error.api_code).to be_nil
      end

      it 'does not set the api message' do
        expect(api_error.api_message).to be_nil
      end

      it 'sets the error message to the default error message' do
        expect(api_error.message).to eq(err.message)
      end
    end

    context 'when the error does not have a recognized API error code' do
      let(:http_code) { 501 }
      let(:api_code) { 'unknown' }
      let(:api_message) { 'test' }
      let(:err) do
        Coinbase::Client::ApiError.new(
          code: http_code,
          response_body: { code: api_code, message: api_message }.to_json
        )
      end

      it 'returns an instance of Coinbase::APIError' do
        expect(api_error).to be_a(described_class)
      end

      it 'sets the http_code attribute' do
        expect(api_error.http_code).to eq(http_code)
      end

      it 'sets the api code' do
        expect(api_error.api_code).to eq(api_code)
      end

      it 'does not set the api message' do
        expect(api_error.api_message).to eq(api_message)
      end

      it 'sets the error message to the default error message' do
        expect(api_error.message).to eq(err.message)
      end
    end
  end
end

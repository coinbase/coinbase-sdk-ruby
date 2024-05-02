# frozen_string_literal: true

describe Coinbase::APIError do
  describe '#from_error' do
    context 'when the error is a generic error' do
      let(:err) { StandardError.new('message') }

      it 'raises an ArgumentError' do
        expect { Coinbase::APIError.from_error(err) }.to raise_error(ArgumentError)
      end
    end

    context 'when the error is an instance of Coinbase::Client::ApiError' do
      let(:err) { Coinbase::Client::ApiError.new('message') }

      it 'returns an instance of Coinbase::APIError' do
        e = Coinbase::APIError.from_error(err)
        expect(e).to be_a(Coinbase::APIError)
      end
    end

    context 'when the error has a recognized API error code' do
      let(:err) do
        Coinbase::Client::ApiError.new(
          code: 501,
          response_body: '{ "code": "unimplemented", "message": "method is not implemented"}'
        )
      end
      it 'returns an instance of the appropriate error class' do
        e = Coinbase::APIError.from_error(err)
        expect(e).to be_a(Coinbase::UnimplementedError)
      end
    end
  end
end

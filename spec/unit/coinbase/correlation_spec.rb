# frozen_string_literal: true

describe Coinbase::Correlation do
  let(:app) do
    Class.new do
      def call(env)
        "callable #{env.request_headers['middle']}"
      end
    end.new
  end
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    let(:env) { instance_double(Faraday::Env) }

    before do
      allow(env).to receive_messages(
        method: 'GET',
        url: URI('https://cdp.api.coinbase.com/v1/users/me'),
        request_headers: {}
      )

      allow(app).to receive(:call)

      middleware.call(env)
    end

    it 'adds the correlation context headers' do # rubocop:disable RSpec/MultipleExpectations
      expect(app).to have_received(:call) do |env|
        expect(env.request_headers['Correlation-Context'])
          .to eq("sdk_version=#{Coinbase::VERSION},sdk_language=ruby")
      end
    end
  end
end

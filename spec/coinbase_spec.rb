# frozen_string_literal: true

describe Coinbase do
  describe '#init' do
    it 'loads environment variables' do
      Coinbase.init
    end
  end
end

describe Coinbase::HistoricalBalance do
    let(:amount) { BigDecimal('123.0') }
    let(:asset) { instance_double('Coinbase::Asset') }
    let(:historical_balance_model) do
      instance_double(
        'Coinbase::Client::HistoricalBalance',
        amount: amount,
        block_height: '456',
        block_hash: 'abc123',
        asset: asset
      )
    end

    describe '.from_model' do
      subject(:historical_balance) { described_class.from_model(historical_balance_model) }

      it 'returns a HistoricalBalance object' do
        expect(historical_balance).to be_a(described_class)
      end

      it 'sets the correct amount' do
        expect(historical_balance.amount).to eq(amount)
      end

      it 'sets the correct block_height' do
        expect(historical_balance.block_height).to eq(BigDecimal('456'))
      end

      it 'sets the correct block_hash' do
        expect(historical_balance.block_hash).to eq('abc123')
      end

      it 'sets the correct asset' do
        expect(historical_balance.asset).to eq(asset)
      end
    end

    describe '#initialize' do
      subject(:historical_balance) do
        described_class.new(
          amount: amount,
          block_height: BigDecimal('456'),
          block_hash: 'abc123',
          asset: asset
        )
      end

      it 'sets the amount' do
        expect(historical_balance.amount).to eq(amount)
      end

      it 'sets the block_height' do
        expect(historical_balance.block_height).to eq(BigDecimal('456'))
      end

      it 'sets the block_hash' do
        expect(historical_balance.block_hash).to eq('abc123')
      end

      it 'sets the asset' do
        expect(historical_balance.asset).to eq(asset)
      end
    end

    describe '#to_s' do
      subject(:historical_balance) do
        described_class.new(
          amount: amount,
          block_height: BigDecimal('456'),
          block_hash: 'abc123',
          asset: asset
        )
      end

      it 'returns a string representation of the HistoricalBalance' do
        expect(historical_balance.to_s).to eq("Coinbase::Balance{amount: '123', block_height: '456', block_hash: 'abc123', asset: '#{asset}'}")
      end
    end

    describe '#inspect' do
      subject(:historical_balance) do
        described_class.new(
          amount: amount,
          block_height: BigDecimal('456'),
          block_hash: 'abc123',
          asset: asset
        )
      end

      it 'returns the same value as to_s' do
        expect(historical_balance.inspect).to eq(historical_balance.to_s)
      end
    end
  end

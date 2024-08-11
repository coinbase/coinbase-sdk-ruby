# frozen_string_literal: true

describe Coinbase::SponsoredSend do
  subject(:sponsored_send) { described_class.new(model) }

  let(:from_key) do
    Eth::Key.new(priv: '0233b43978845c03783510106941f42370e0f11022b0c3b717c0791d046f4536')
  end
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:typed_data_hash) { '0x7523946e17c0b8090ee18c84d6f9a8d63bab4d579a6507f0998dde0791891823' }
  let(:typed_data_signature) do
    '0x2f72103b6c803dd64a681874afd13d8a946274c075b4d547f910836223564858222840424da7bb5ef49d9a1047' \
      '54d6ddc9b2fc49447be05e89b77d6e41c9fbad1c'
  end
  let(:transaction_hash) { '0xdea671372a8fff080950d09ad5994145a661c8e95a9216ef34772a19191b5690' }
  let(:transaction_link) { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
  let(:model) do
    Coinbase::Client::SponsoredSend.new(status: 'pending', typed_data_hash: typed_data_hash)
  end

  let(:signed_model) do
    Coinbase::Client::SponsoredSend.new(
      status: 'signed',
      typed_data_hash: typed_data_hash,
      signature: typed_data_signature
    )
  end

  let(:completed_model) do
    Coinbase::Client::SponsoredSend.new(
      status: 'complete',
      typed_data_hash: typed_data_hash,
      signature: typed_data_signature,
      transaction_hash: transaction_hash,
      transaction_link: transaction_link
    )
  end

  let(:signed_send) { described_class.new(signed_model) }
  let(:completed_send) { described_class.new(completed_model) }

  describe '#initialize' do
    it 'initializes a new SponsoredSend' do
      expect(sponsored_send).to be_a(described_class)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#typed_data_hash' do
    it 'returns the typed data hash' do
      expect(sponsored_send.typed_data_hash).to eq(typed_data_hash)
    end
  end

  describe '#signature' do
    context 'when the sponsored send has not been signed' do
      it 'returns nil' do
        expect(sponsored_send.signature).to be_nil
      end
    end

    context 'when the sponsored send has been completed on chain' do
      subject(:sponsored_send) { completed_send }

      it 'returns the signature' do
        expect(sponsored_send.signature).to eq(typed_data_signature)
      end
    end

    context 'when the sponsored send has been signed in-band' do
      before { sponsored_send.sign(from_key) }

      it 'returns the signature' do
        expect(sponsored_send.signature).not_to be_empty
      end
    end
  end

  describe '#signed?' do
    context 'when the sponsored send model has not been signed' do
      it 'returns false' do
        expect(sponsored_send).not_to be_signed
      end

      context 'when the sponsored send is then signed' do
        before { sponsored_send.sign(from_key) }

        it 'returns true' do
          expect(sponsored_send).to be_signed
        end
      end
    end

    context 'when the sponsored send model has been signed' do
      subject(:sponsored_send) { signed_send }

      it 'returns true' do
        expect(sponsored_send).to be_signed
      end
    end
  end

  describe '#transaction_hash' do
    context 'when the sponsored send has not been broadcast on chain' do
      it 'returns nil' do
        expect(sponsored_send.transaction_hash).to be_nil
      end
    end

    context 'when the sponsored send has been completed on chain' do
      subject(:sponsored_send) { completed_send }

      it 'returns the transaction hash' do
        expect(sponsored_send.transaction_hash).to eq(transaction_hash)
      end
    end
  end

  describe '#status' do
    it 'returns the status' do
      expect(sponsored_send.status).to eq('pending')
    end
  end

  describe '#terminal_state?' do
    let(:model) do
      Coinbase::Client::SponsoredSend.new(
        status: status,
        typed_data_hash: typed_data_hash
      )
    end

    %w[pending submitted signed].each do |state|
      context "when the state is #{state}" do
        let(:status) { state }

        it 'returns false' do
          expect(sponsored_send.terminal_state?).to be(false)
        end
      end
    end

    %w[complete failed].each do |state|
      context "when the state is #{state}" do
        let(:status) { state }

        it 'returns true' do
          expect(sponsored_send.terminal_state?).to be(true)
        end
      end
    end
  end

  describe '#transaction_link' do
    context 'when the sponsored send has not been broadcast' do
      it 'returns nil' do
        expect(sponsored_send.transaction_link).to be_nil
      end
    end

    context 'when the sponsored send has been completed' do
      subject(:sponsored_send) do
        described_class.new(completed_model)
      end

      it 'returns the transaction link' do
        expect(sponsored_send.transaction_link).to eq(transaction_link)
      end
    end
  end

  describe '#sign' do
    subject(:signature) { sponsored_send.sign(from_key) }

    before { signature }

    it 'returns a string' do
      expect(signature).to be_a(String)
    end

    it 'returns a hex-prefixed value' do
      expect(Eth::Util.prefixed?(signature)).not_to be_nil
    end

    context 'when it is signed again' do
      it 'raises an error' do
        expect { sponsored_send.sign(from_key) }.to raise_error(Coinbase::AlreadySignedError)
      end
    end
  end

  describe '#inspect' do
    it 'includes sponsored send details' do
      expect(sponsored_send.inspect).to include(sponsored_send.status.to_s)
    end

    it 'returns the same value as to_s' do
      expect(sponsored_send.inspect).to eq(sponsored_send.to_s)
    end

    context 'when the sponsored send has been completed on chain' do
      subject(:sponsored_send) do
        described_class.new(completed_model)
      end

      it 'includes the transaction hash' do
        expect(sponsored_send.inspect).to include(
          sponsored_send.transaction_hash,
          sponsored_send.transaction_link
        )
      end
    end
  end
end

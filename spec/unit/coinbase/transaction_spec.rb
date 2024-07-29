# frozen_string_literal: true

describe Coinbase::Transaction do
  let(:from_key) do
    Eth::Key.new(priv: '0233b43978845c03783510106941f42370e0f11022b0c3b717c0791d046f4536')
  end
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:from_address_id) { from_key.address.to_s }
  let(:eth_asset) do
    Coinbase::Client::Asset.new(network_id: 'base-sepolia', asset_id: 'eth', decimals: 18)
  end
  let(:atomic_amount) { 10_000_000_000_000 }
  let(:whole_amount) { Coinbase::Asset.from_model(eth_asset).from_atomic_amount(atomic_amount) }
  let(:to_address_id) { '0xe317065De795eFBaC71cf00114c7252BFcd23c29'.downcase }
  let(:unsigned_payload) do \
    '7b2274797065223a22307832222c22636861696e4964223a2230783134613334222c226e6f6e6365223a22307830' \
      '222c22746f223a2230786533313730363564653739356566626163373163663030313134633732353262666364' \
      '3233633239222c22676173223a22307835323038222c226761735072696365223a6e756c6c2c226d6178507269' \
      '6f72697479466565506572476173223a2230786634323430222c226d6178466565506572476173223a22307866' \
      '34343265222c2276616c7565223a2230783931383465373261303030222c22696e707574223a223078222c2261' \
      '63636573734c697374223a5b5d2c2276223a22307830222c2272223a22307830222c2273223a22307830222c22' \
      '79506172697479223a22307830222c2268617368223a2230783232373461653832663838623664303334393066' \
      '3561663235343534383764633862316239623538646461303336326134316436313339346136346662646634227d'
  end
  let(:signed_payload) do \
    '02f87183014a3480830f4240830f442e82520894e317065de795efbac71cf00114c7252bfcd23c298609184e72a0' \
      '0080c080a0eab79ad9a2933fcea4acc375ed9cffb9345623f9f377c8afca59c368e5a6a20da071f32cafa36a49' \
      '5531dd76a4edac70280eda4a18bdcbbcc5496c41fe884b6aba'
  end
  let(:transaction_hash) { '0xdea671372a8fff080950d09ad5994145a661c8e95a9216ef34772a19191b5690' }
  let(:transaction_link) { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
  let(:model) { build(:transaction_model, from_address_id: from_address_id, unsigned_payload: unsigned_payload) }

  let(:signed_model) do
    Coinbase::Client::Transaction.new(
      status: 'signed',
      from_address_id: from_address_id,
      unsigned_payload: unsigned_payload,
      signed_payload: signed_payload
    )
  end

  let(:broadcasted_model) do
    Coinbase::Client::Transaction.new(
      status: 'broadcast',
      from_address_id: from_address_id,
      unsigned_payload: unsigned_payload,
      signed_payload: signed_payload,
      transaction_hash: transaction_hash,
      transaction_link: transaction_link
    )
  end

  let(:signed_transaction) { described_class.new(signed_model) }
  let(:broadcasted_transaction) { described_class.new(broadcasted_model) }

  subject(:transaction) { described_class.new(model) }

  describe '#initialize' do
    it 'initializes a new Transaction' do
      expect(transaction).to be_a(Coinbase::Transaction)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#unsigned_payload' do
    it 'returns the unsigned payload' do
      expect(transaction.unsigned_payload).to eq(unsigned_payload)
    end
  end

  describe '#signed_payload' do
    context 'when the transaction has not been broadcast on chain' do
      it 'returns nil' do
        expect(transaction.signed_payload).to be_nil
      end
    end

    context 'when the transaction has been broadcast on chain' do
      subject(:transaction) { broadcasted_transaction }

      it 'returns the signed payload' do
        expect(transaction.signed_payload).to eq(signed_payload)
      end
    end
  end

  describe '#signed?' do
    context 'when the transaction model has not been signed' do
      it 'returns false' do
        expect(transaction).not_to be_signed
      end

      context 'and the transaction is then signed' do
        before { transaction.sign(from_key) }

        it 'returns true' do
          expect(transaction).to be_signed
        end
      end
    end

    context 'when the transaction model has been signed' do
      subject(:transaction) { signed_transaction }

      it 'returns true' do
        expect(transaction).to be_signed
      end
    end
  end

  describe '#transaction_hash' do
    context 'when the transaction has not been broadcast on chain' do
      it 'returns nil' do
        expect(transaction.transaction_hash).to be_nil
      end
    end
    context 'when the transaction has been broadcast on chain' do
      subject(:transaction) { broadcasted_transaction }

      it 'returns the transaction hash' do
        expect(transaction.transaction_hash).to eq(transaction_hash)
      end
    end
  end

  describe '#status' do
    it 'returns the status' do
      expect(transaction.status).to eq('pending')
    end
  end

  describe '#from_address_id' do
    it 'returns the from address' do
      expect(transaction.from_address_id).to eq(from_address_id)
    end
  end

  describe '#terminal_state?' do
    let(:model) do
      Coinbase::Client::Transaction.new(
        status: status,
        from_address_id: from_address_id,
        unsigned_payload: unsigned_payload
      )
    end

    %w[pending broadcast].each do |state|
      context "when the state is #{state}" do
        let(:status) { state }

        it 'returns false' do
          expect(transaction.terminal_state?).to be(false)
        end
      end
    end

    %w[complete failed].each do |state|
      context "when the state is #{state}" do
        let(:status) { state }

        it 'returns true' do
          expect(transaction.terminal_state?).to be(true)
        end
      end
    end
  end

  describe '#transaction_link' do
    context 'when the transaction has not been broadcast' do
      it 'returns nil' do
        expect(transaction.transaction_link).to be_nil
      end
    end

    context 'when the transaction has been broadcast' do
      subject(:transaction) do
        described_class.new(broadcasted_model)
      end

      it 'returns the transaction link' do
        expect(transaction.transaction_link).to eq(transaction_link)
      end
    end
  end

  describe '#raw' do
    context 'when the model is unsigned' do
      it 'returns the raw transaction' do
        expect(transaction.raw).to be_a(Eth::Tx::Eip1559)
      end

      it 'returns the correct amount' do
        expect(transaction.raw.amount).to eq(atomic_amount)
      end

      it 'returns the correct chain ID' do
        expect(transaction.raw.chain_id).to eq(Coinbase::BASE_SEPOLIA.chain_id)
      end

      it 'returns the correct sanitized sender address' do
        expect(transaction.raw.sender).to eq(
          Eth::Tx.sanitize_address(from_address_id).encode('ascii')
        )
      end

      it 'returns the correct sanitized destination address' do
        expect(transaction.raw.destination).to eq(
          Eth::Tx.sanitize_address(to_address_id).encode('ascii')
        )
      end

      it 'returns the correct nonce' do
        expect(transaction.raw.signer_nonce).to eq(0)
      end

      it 'returns the correct gas limit' do
        expect(transaction.raw.gas_limit).to eq(21_000)
      end

      it 'returns the correct max priority fee per gas' do
        expect(transaction.raw.max_priority_fee_per_gas).to eq(1_000_000)
      end

      it 'returns an unsigned transaction' do
        expect(Eth::Tx.signed?(transaction.raw)).to be(false)
      end

      context 'and the transaction is signed' do
        before { transaction.sign(from_key) }

        it 'returns a signed transaction' do
          expect(Eth::Tx.signed?(transaction.raw)).to be(true)
        end
      end
    end

    context 'when the model is signed' do
      subject(:transaction) { described_class.new(broadcasted_model) }

      it 'returns the raw transaction' do
        expect(transaction.raw).to be_a(Eth::Tx::Eip1559)
      end

      it 'returns the correct amount' do
        expect(transaction.raw.amount).to eq(atomic_amount)
      end

      it 'returns the correct chain ID' do
        expect(transaction.raw.chain_id).to eq(Coinbase::BASE_SEPOLIA.chain_id)
      end

      it 'returns the correct sanitized sender address' do
        expect(transaction.raw.sender).to eq(
          Eth::Tx.sanitize_address(from_address_id).encode('ascii')
        )
      end

      it 'returns the correct sanitized destination address' do
        expect(transaction.raw.destination).to eq(
          Eth::Tx.sanitize_address(to_address_id).encode('ascii').downcase
        )
      end

      it 'returns the correct nonce' do
        expect(transaction.raw.signer_nonce).to eq(0)
      end

      it 'returns the correct gas limit' do
        expect(transaction.raw.gas_limit).to eq(21_000)
      end

      it 'returns the correct max priority fee per gas' do
        expect(transaction.raw.max_priority_fee_per_gas).to eq(1_000_000)
      end

      it 'returns a signed transaction' do
        expect(Eth::Tx.signed?(transaction.raw)).to be(true)
      end
    end
  end

  describe '#sign' do
    subject(:signature) { transaction.sign(from_key) }

    before { signature }

    it 'returns a string' do
      expect(signature).to be_a(String)
    end

    it 'signs the raw transaction' do
      expect(Eth::Tx.signed?(transaction.raw)).to be(true)
    end

    it 'returns a hex representation of the signed raw transaction' do
      expect(signature).to eq(transaction.raw.hex)
    end

    context 'when it is signed again' do
      it 'raises an error' do
        expect { transaction.sign(from_key) }.to raise_error(Eth::Signature::SignatureError)
      end
    end
  end

  describe '#inspect' do
    it 'includes transaction details' do
      expect(transaction.inspect).to include(transaction.status.to_s)
    end

    it 'returns the same value as to_s' do
      expect(transaction.inspect).to eq(transaction.to_s)
    end

    context 'when the transaction has been broadcast on chain' do
      subject(:transaction) do
        described_class.new(broadcasted_model)
      end

      it 'includes the transaction hash' do
        expect(transaction.inspect).to include(transaction.transaction_hash)
      end
    end
  end
end

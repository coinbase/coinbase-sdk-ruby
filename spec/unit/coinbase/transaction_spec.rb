# frozen_string_literal: true

describe Coinbase::Transaction do
  let(:from_key) { build(:key) }
  let(:to_address_id) { '0xe317065De795eFBaC71cf00114c7252BFcd23c29'.downcase }
  let(:transaction_model) { build(:transaction_model, from_address_id: from_key.address.to_s) }
  subject(:transaction) { build(:transaction, model: transaction_model) }

  describe '#initialize' do
    it 'initializes a new Transaction' do
      expect(transaction).to be_a(Coinbase::Transaction)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(build(:balance_model))
        end.to raise_error(RuntimeError)
      end
    end
  end

  describe '#unsigned_payload' do
    it 'returns the unsigned payload' do
      expect(transaction.unsigned_payload).to eq(transaction_model.unsigned_payload)
    end
  end

  describe '#signed_payload' do
    context 'when the transaction has not been broadcast on chain' do
      it 'returns nil' do
        expect(transaction.signed_payload).to be_nil
      end
    end

    context 'when the transaction has been broadcast on chain' do
      let(:transaction_model) { build(:transaction_model, :broadcasted) }

      it 'returns the signed payload' do
        expect(transaction.signed_payload).to eq(transaction_model.signed_payload)
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
      let(:transaction_model) { build(:transaction_model, :signed) }

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
      subject(:transaction_model) { build(:transaction_model, :broadcasted) }

      it 'returns the transaction hash' do
        expect(transaction.transaction_hash).to eq(transaction_model.transaction_hash)
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
      expect(transaction.from_address_id).to eq(transaction_model.from_address_id)
    end
  end

  describe '#terminal_state?' do
    let(:transaction_model) { build(:transaction_model, status: status) }

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
      let(:transaction_model) { build(:transaction_model, :broadcasted) }

      it 'returns the transaction link' do
        expect(transaction.transaction_link).to eq(transaction_model.transaction_link)
      end
    end
  end

  describe '#raw' do
    let(:atomic_amount) { 10_000_000_000_000 }
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
        sanatized_address = Eth::Tx.sanitize_address(transaction_model.from_address_id).encode('ascii')
        expect(transaction.raw.sender).to eq(sanatized_address)
      end

      it 'returns the correct sanitized destination address' do
        sanatized_address = Eth::Tx.sanitize_address(to_address_id).encode('ascii')
        expect(transaction.raw.destination).to eq(sanatized_address)
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
      subject(:transaction_model) { build(:transaction_model, :broadcasted) }

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
          Eth::Tx.sanitize_address(transaction_model.from_address_id).encode('ascii')
        )
      end

      it 'returns the correct sanitized destination address' do
        sanatized_address = Eth::Tx.sanitize_address(to_address_id).encode('ascii')
        expect(transaction.raw.destination).to eq(sanatized_address.downcase)
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
      let(:transaction_model) { build(:transaction_model, :broadcasted) }

      it 'includes the transaction hash' do
        expect(transaction.inspect).to include(transaction.transaction_hash)
      end
    end
  end
end

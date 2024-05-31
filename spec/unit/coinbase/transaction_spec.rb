# frozen_string_literal: true

describe Coinbase::Transaction do
  let(:from_key) { Eth::Key.new }
  let(:network_id) { :base_sepolia }
  let(:wallet_id) { SecureRandom.uuid }
  let(:from_address_id) { from_key.address.to_s }
  let(:amount) { BigDecimal(100) }
  let(:eth_amount) { amount / BigDecimal(Coinbase::WEI_PER_ETHER.to_s) }
  let(:to_address_id) { '0x4D9E4F3f4D1A8B5F4f7b1F5b5C7b8d6b2B3b1b0b' }
  let(:unsigned_payload) do \
    '7b2274797065223a22307832222c22636861696e4964223a2230783134613334222c226e6f6e63' \
'65223a22307830222c22746f223a22307834643965346633663464316138623566346637623166' \
'356235633762386436623262336231623062222c22676173223a22307835323038222c22676173' \
'5072696365223a6e756c6c2c226d61785072696f72697479466565506572476173223a223078' \
'3539363832663030222c226d6178466565506572476173223a2230783539363832663030222c22' \
'76616c7565223a2230783536626337356532643633313030303030222c22696e707574223a22' \
'3078222c226163636573734c697374223a5b5d2c2276223a22307830222c2272223a2230783022' \
'2c2273223a22307830222c2279506172697479223a22307830222c2268617368223a2230783664' \
'633334306534643663323633653363396561396135656438646561346332383966613861363966' \
'3031653635393462333732386230386138323335333433227d'
  end
  let(:signed_payload) do \
    '02f86b83014a3401830f4240830f4350825208946cd01c0f55ce9e0bf78f5e90f72b4345b' \
    '16d515d0280c001a0566afb8ab09129b3f5b666c3a1e4a7e92ae12bbee8c75b4c6e0c46f6' \
    '6dd10094a02115d1b52c49b39b6cb520077161c9bf636730b1b40e749250743f4524e9e4ba'
  end
  let(:transaction_hash) { '0x6c087c1676e8269dd81e0777244584d0cbfd39b6997b3477242a008fa9349e11' }
  let(:model) do
    Coinbase::Client::Transaction.new(
      status: 'pending',
      from_address_id: from_address_id,
      unsigned_payload: unsigned_payload
    )
  end

  let(:broadcasted_model) do
    Coinbase::Client::Transaction.new(
      status: 'broadcast',
      from_address_id: from_address_id,
      unsigned_payload: unsigned_payload,
      signed_payload: signed_payload,
      transaction_hash: transaction_hash
    )
  end

  subject(:transaction) do
    described_class.new(model)
  end

  describe '#initialize' do
    it 'initializes a new Transaction' do
      expect(transaction).to be_a(Coinbase::Transaction)
    end

    context 'when initialized with a model of a different type' do
      it 'raises an error' do
        expect do
          described_class.new(Coinbase::Client::Balance.new)
        end.to raise_error
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
      subject(:transaction) do
        described_class.new(broadcasted_model)
      end

      it 'returns the signed payload' do
        expect(transaction.signed_payload).to eq(signed_payload)
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
      subject(:transaction) do
        described_class.new(broadcasted_model)
      end

      it 'returns the transaction hash' do
        expect(transaction.transaction_hash).to eq(transaction_hash)
      end
    end
  end

  describe '#raw' do
    it 'returns the rraw transaction' do
      expect(transaction.raw).to be_a(Eth::Tx::Eip1559)
    end

    it 'returns the correct amount' do
      expect(transaction.raw.amount).to eq(amount * Coinbase::WEI_PER_ETHER)
    end

    it 'returns the correct chain ID' do
      expect(transaction.raw.chain_id).to eq(Coinbase::BASE_SEPOLIA.chain_id)
    end

    it 'returns the correct sender address' do
      expect(transaction.raw.sender).to eq(from_address_id)
    end

    it 'returns the correct destination address' do
      expect(transaction.raw.destination).to eq(to_address_id)
    end

    it 'returns the correct nonce' do
      expect(transaction.raw.signer_nonce).to eq(0)
    end

    it 'returns the correct gas limit' do
      expect(transaction.raw.gas_limit).to eq(21_000)
    end

    it 'returns the correct max priority fee per gas' do
      expect(transaction.raw.max_priority_fee_per_gas).to eq(1_500_000_000)
    end
  end

  describe '#sign' do
    subject(:signature) { transaction.sign(from_key) }

    before { signature }

    it 'returns a string' do
      expect(signature).to be_a(String)
    end

    it 'signs the raw transaction' do
      expect(transaction.raw.signature_r).not_to be_empty
      expect(transaction.raw.signature_s).not_to be_empty
    end

    it 'returns a hex representation of the signed raw transaction' do
      expect(signature).to eq(transaction.raw.hex)
    end

    context 'when it is signed again' do
      it 'raises an error' do
        expect { transaction.sign(from_key) }.to raise_error
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

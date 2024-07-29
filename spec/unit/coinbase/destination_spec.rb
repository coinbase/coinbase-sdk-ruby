# frozen_string_literal: true

describe Coinbase::Destination do
  let(:network_id) { :base_sepolia }
  let(:address_id) { Eth::Key.new.address.to_s }

  subject(:destination) { described_class.new(model, network_id: network_id) }

  describe '#initialize' do
    context 'when initialized with a Coinbase::Destination' do
      let(:model) do
        instance_double(Coinbase::Destination, address_id: address_id, network_id: network_id)
      end

      before do
        allow(Coinbase::Destination).to receive(:===).with(model).and_return(true)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network_id' do
        expect(destination.network_id).to eq(network_id)
      end

      context 'when network_id does not match' do
        let(:model) do
          instance_double(Coinbase::Destination, address_id: address_id, network_id: :ethereum_mainnet)
        end

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network_id: network_id)
          end.to raise_error(ArgumentError, 'destination network must match destination')
        end
      end
    end

    context 'when initialized with a Coinbase::Wallet' do
      let(:default_address) { instance_double(Coinbase::Address, id: address_id, network_id: network_id) }
      let(:model) { instance_double(Coinbase::Wallet, default_address: default_address, network_id: network_id) }

      before do
        allow(Coinbase::Wallet).to receive(:===).with(model).and_return(true)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network_id' do
        expect(destination.network_id).to eq(network_id)
      end

      context 'when network_id does not match' do
        let(:model) do
          instance_double(Coinbase::Wallet, default_address: default_address, network_id: :ethereum_mainnet)
        end

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network_id: network_id)
          end.to raise_error(ArgumentError, 'destination network must match wallet')
        end
      end

      context 'when wallet does not have a default address' do
        let(:model) { instance_double(Coinbase::Wallet, default_address: nil, network_id: network_id) }

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network_id: network_id)
          end.to raise_error(ArgumentError, 'destination wallet must have default address')
        end
      end
    end

    context 'when model is a Coinbase::WalletAddress' do
      let(:address_network) { network_id }
      let(:model) do
        Coinbase::WalletAddress.new(
          Coinbase::Client::Address.new(
            network_id: address_network,
            address_id: address_id,
            wallet_id: SecureRandom.uuid
          ),
          nil
        )
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network_id' do
        expect(destination.network_id).to eq(network_id)
      end

      context 'when network_id does not match' do
        let(:address_network) { :ethereum_mainnet }

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network_id: network_id)
          end.to raise_error(ArgumentError, 'destination network must match address')
        end
      end
    end

    context 'when initialized with a Coinbase::ExternalAddress' do
      let(:address_network) { network_id }
      let(:model) { Coinbase::ExternalAddress.new(address_network, address_id) }

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network_id' do
        expect(destination.network_id).to eq(network_id)
      end

      context 'when network_id does not match' do
        let(:address_network) { :ethereum_mainnet }

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network_id: network_id)
          end.to raise_error(ArgumentError, 'destination network must match address')
        end
      end
    end

    context 'when model is a String' do
      let(:model) { address_id }

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network_id to the provided network_id' do
        expect(destination.network_id).to eq(network_id)
      end
    end

    context 'when model is an unsupported type' do
      it 'raises an ArgumentError' do
        expect do
          described_class.new(123)
        end.to raise_error(ArgumentError, 'unsupported destination type: Integer')
      end
    end
  end
end

# frozen_string_literal: true

describe Coinbase::Destination do
  subject(:destination) { described_class.new(model, network: network) }

  let(:network_id) { :base_sepolia }
  let(:network) { build(:network, network_id) }
  let(:address_id) { Eth::Key.new.address.to_s }

  before do
    allow(Coinbase::Network).to receive(:from_id).with(network).and_return(network)
  end

  describe '#initialize' do
    context 'when initialized with a Coinbase::Destination' do
      let(:model) do
        instance_double(described_class, address_id: address_id, network: network)
      end

      before do
        allow(described_class).to receive(:===).with(model).and_return(true)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network' do
        expect(destination.network).to eq(network)
      end

      context 'when the networks do not match' do
        let(:destination_network) { build(:network, :ethereum_mainnet) }
        let(:model) do
          instance_double(described_class, address_id: address_id, network: destination_network)
        end

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network: network)
          end.to raise_error(ArgumentError, 'destination network must match destination')
        end
      end
    end

    context 'when initialized with a Coinbase::Wallet' do
      let(:default_address_network_id) { network_id }
      let(:default_address_network) { network }
      let(:default_address_model) { build(:address_model, default_address_network_id) }
      let(:model) do
        instance_double(
          Coinbase::Wallet,
          default_address: Coinbase::WalletAddress.new(default_address_model, nil),
          network: network
        )
      end

      before do
        # The wallet model's network method fetches the network constant from the network ID.
        allow(Coinbase::Network)
          .to receive(:from_id)
          .with(Coinbase.normalize_network(default_address_network_id))
          .and_return(default_address_network)

        allow(Coinbase::Wallet).to receive(:===).with(model).and_return(true)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(default_address_model.address_id)
      end

      it 'sets the network' do
        expect(destination.network).to eq(default_address_network)
      end

      context 'when network does not match' do
        let(:default_address_network_id) { :ethereum_mainnet }
        let(:default_address_network) { build(:network, default_address_network_id) }
        let(:default_address_model) { build(:address_model, default_address_network_id) }
        let(:model) do
          instance_double(
            Coinbase::Wallet,
            default_address: Coinbase::WalletAddress.new(default_address_model, nil),
            network: default_address_network
          )
        end

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network: network)
          end.to raise_error(ArgumentError, 'destination network must match wallet')
        end
      end

      context 'when wallet does not have a default address' do
        let(:model) do
          instance_double(Coinbase::Wallet, network: network, default_address: nil)
        end

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network: network)
          end.to raise_error(ArgumentError, 'destination wallet must have default address')
        end
      end
    end

    context 'when model is a Coinbase::WalletAddress' do
      let(:address_network_id) { network_id }
      let(:address_network) { network }
      let(:address_model) { build(:address_model, address_network_id) }
      let(:model) { Coinbase::WalletAddress.new(address_model, nil) }

      before do
        allow(Coinbase::Network)
          .to receive(:from_id)
          .with(Coinbase.normalize_network(address_network_id))
          .and_return(address_network)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_model.address_id)
      end

      it 'sets the network' do
        expect(destination.network).to eq(network)
      end

      context 'when networks do not match' do
        let(:address_network_id) { :ethereum_mainnet }
        let(:address_network) { build(:network, address_network_id) }

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network: network)
          end.to raise_error(ArgumentError, 'destination network must match address')
        end
      end
    end

    context 'when initialized with a Coinbase::ExternalAddress' do
      let(:address_network_id) { network_id }
      let(:address_network) { network }
      let(:model) { Coinbase::ExternalAddress.new(address_network_id, address_id) }

      before do
        allow(Coinbase::Network)
          .to receive(:from_id)
          .with(address_network_id)
          .and_return(address_network)
      end

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network' do
        expect(destination.network).to eq(address_network)
      end

      context 'when network does not match' do
        let(:address_network_id) { :ethereum_mainnet }
        let(:address_network) { build(:network, address_network_id) }

        it 'raises an ArgumentError' do
          expect do
            described_class.new(model, network: network)
          end.to raise_error(ArgumentError, 'destination network must match address')
        end
      end
    end

    context 'when model is a String' do
      let(:model) { address_id }

      it 'sets the address_id' do
        expect(destination.address_id).to eq(address_id)
      end

      it 'sets the network to the provided network' do
        expect(destination.network).to eq(network)
      end
    end

    context 'when model is an unsupported type' do
      it 'raises an ArgumentError' do
        expect do
          described_class.new(123, network: network)
        end.to raise_error(ArgumentError, 'unsupported destination type: Integer')
      end
    end
  end
end

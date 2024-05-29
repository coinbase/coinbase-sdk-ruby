# frozen_string_literal: true

require 'faraday'

module Coinbase
  # A representation of a Stake operation used for a end-user custody flow.
  class Stake
    class << self
      VALID_PROTOCOL_NETWORK = [
        'ethereum-holesky'
      ].freeze

      # Builds a stake operation for a protocol on a given network.
      # @param protocol [Symbol] The protocol name.
      # @param network [Symbol] The network name.
      # @param params  [Hash] The parameters needed to create a stake operation.
      # @param opts [Hash] Optional parameters related to a stake operation.
      # @return [String] An unsigned transaction used to stake.
      def build_stake_operation(protocol, network, params, opts = { mode: :partial })
        return if not_valid_protocol_network?(protocol, network)

        body = {}

        case protocol_network(protocol, network)
        when 'ethereum-holesky'
          return if missing_required_params?(params, %i[address amount])
          return if not_partial?(opts)

          body = {
            'action' => action("#{protocol}_kiln".to_sym, network, :stake),
            'ethereum_kiln_staking_parameters' => {
              'stake_parameters' => {
                'staker_address' => (params[:address]).to_s,
                'amount' => {
                  'value' => (params[:amount]).to_s,
                  'currency' => 'ETH'
                }
              }
            }
          }
        end

        call_client(body)
      end

      # Builds an unstake operation for a protocol on a given network.
      # @param protocol [Symbol] The protocol name.
      # @param network [Symbol] The network name.
      # @param params  [Hash] The parameters needed to create an unstake operation.
      # @param opts [Hash] Optional parameters related to an unstake operation.
      # @return [String] An unsigned transaction used to unstake.
      def build_unstake_operation(protocol, network, params, opts = { mode: :partial })
        return if not_valid_protocol_network?(protocol, network)

        body = {}

        case protocol_network(protocol, network)
        when 'ethereum-holesky'
          return if missing_required_params?(params, %i[address amount])
          return if not_partial?(opts)

          body = {
            'action' => action("#{protocol}_kiln".to_sym, network, :unstake),
            'ethereum_kiln_staking_parameters' => {
              'unstake_parameters' => {
                'staker_address' => (params[:address]).to_s,
                'amount' => {
                  'value' => (params[:amount]).to_s,
                  'currency' => 'ETH'
                }
              }
            }
          }
        end

        call_client(body)
      end

      # Builds a claim_stake operation for a protocol on a given network.
      # @param protocol [Symbol] The protocol name.
      # @param network [Symbol] The network name.
      # @param params  [Hash] The parameters needed to create a claim_stake operation.
      # @param opts [Hash] Optional parameters related to a claim_stake operation.
      # @return [String] An unsigned transaction used to claim_stake.
      def build_claim_stake_operation(protocol, network, params, opts = { mode: :partial })
        return if not_valid_protocol_network?(protocol, network)

        body = {}

        case protocol_network(protocol, network)
        when 'ethereum-holesky'
          return if missing_required_params?(params, [:address])
          return if not_partial?(opts)

          body = {
            'action' => action("#{protocol}_kiln".to_sym, network, :claim_stake),
            'ethereum_kiln_staking_parameters' => {
              'claim_stake_parameters' => {
                'staker_address' => (params[:address]).to_s
              }
            }
          }
        end

        call_client(body)
      end

      # Checks if the protocol/network combo is supported.
      #  @param protocol [Symbol] The protocol name.
      #  @param network [Symbol] The network name.
      #  @return [Boolean] If the protocol-network combo is supported.
      def not_valid_protocol_network?(protocol, network)
        if VALID_PROTOCOL_NETWORK.none?(protocol_network(
                                          protocol, network
                                        ))
          raise ArgumentError,
                "Unsupported #{protocol_network(protocol, network)}"
        end
      end

      # Checks to see if the input parameters have all required fields.
      # @param params [Hash] User provided parameters for a staking operation.
      # @param required_params [Hash] The required parameters needed to create a staking operation.
      # @return [Boolean] If the input parameters have all the required parameters populated.
      def missing_required_params?(params, required_params)
        raise ArgumentError, "missing required params #{required_params}" unless required_params.all? do |key|
          params.key?(key)
        end
      end

      # Creates an action resource name for the body of a staking operation.
      # @param protocol [Symbol] The protocol name.
      # @param network [Symbol] The network name.
      # @param action [Symbol] The action which translates to a specific staking operation.
      # @return [String] The action resource name.
      def action(protocol, network, action)
        "protocols/#{protocol}/networks/#{network}/actions/#{action}"
      end

      # Creates a protocol-network pair.
      # @param protocol [Symbol] The protocol name.
      # @param network [Symbol] The network name.
      # @return [String] The protocol-network combo.
      def protocol_network(protocol, network)
        "#{protocol}-#{network}"
      end

      # Checks if the mode is set to partial.
      # @param opts [Hash] The options passed in by the user.
      # @return [Boolean] If the mode is partial.
      def not_partial?(opts)
        raise ArgumentError, "required mode to be 'partial'" if opts[:mode] != :partial
      end

      # Sets up the options and calls the Staking API service backend.
      # @param body [Hash] Holds the different options passed into the API call.
      # @return [String] The unsigned transaction from the response body.
      def call_client(body)
        opts = {
          header_params: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          },
          query_params: {},
          return_type: 'Object'
        }

        call_opts = opts.merge(body: body)

        response = Coinbase.call_api do
          staking_api.call_api(:POST, '/v1/workflows', call_opts)
        end

        response[0].dig(:steps, 0, :txStepOutput, :unsignedTx)
      end

      # Creates the Staking API client used to create staking operations.
      # @return [ApiClient] The Staking API client.
      def staking_api
        @staking_api ||= Coinbase::Client::ApiClient.new(Middleware.config).tap do |client|
          client.config.base_path = '/staking/orchestration'
        end
      end
    end
  end
end

=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha

Generated by: https://openapi-generator.tech
Generator version: 7.10.0

=end

require 'date'
require 'time'

module Coinbase::Client
  # The metadata for the reputation score of onchain address.
  class AddressReputationMetadata
    # The total number of transactions performed by the address.
    attr_accessor :total_transactions

    # The number of unique days the address was active.
    attr_accessor :unique_days_active

    # The longest streak of consecutive active days.
    attr_accessor :longest_active_streak

    # The current streak of consecutive active days.
    attr_accessor :current_active_streak

    # The total number of days the address has been active.
    attr_accessor :activity_period_days

    # The number of token swaps performed by the address.
    attr_accessor :token_swaps_performed

    # The number of bridge transactions performed by the address.
    attr_accessor :bridge_transactions_performed

    # The number of lend, borrow, or stake transactions performed by the address.
    attr_accessor :lend_borrow_stake_transactions

    # The number of interactions with ENS contracts.
    attr_accessor :ens_contract_interactions

    # The number of smart contracts deployed by the address.
    attr_accessor :smart_contract_deployments

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        :'total_transactions' => :'total_transactions',
        :'unique_days_active' => :'unique_days_active',
        :'longest_active_streak' => :'longest_active_streak',
        :'current_active_streak' => :'current_active_streak',
        :'activity_period_days' => :'activity_period_days',
        :'token_swaps_performed' => :'token_swaps_performed',
        :'bridge_transactions_performed' => :'bridge_transactions_performed',
        :'lend_borrow_stake_transactions' => :'lend_borrow_stake_transactions',
        :'ens_contract_interactions' => :'ens_contract_interactions',
        :'smart_contract_deployments' => :'smart_contract_deployments'
      }
    end

    # Returns all the JSON keys this model knows about
    def self.acceptable_attributes
      attribute_map.values
    end

    # Attribute type mapping.
    def self.openapi_types
      {
        :'total_transactions' => :'Integer',
        :'unique_days_active' => :'Integer',
        :'longest_active_streak' => :'Integer',
        :'current_active_streak' => :'Integer',
        :'activity_period_days' => :'Integer',
        :'token_swaps_performed' => :'Integer',
        :'bridge_transactions_performed' => :'Integer',
        :'lend_borrow_stake_transactions' => :'Integer',
        :'ens_contract_interactions' => :'Integer',
        :'smart_contract_deployments' => :'Integer'
      }
    end

    # List of attributes with nullable: true
    def self.openapi_nullable
      Set.new([
      ])
    end

    # Initializes the object
    # @param [Hash] attributes Model attributes in the form of hash
    def initialize(attributes = {})
      if (!attributes.is_a?(Hash))
        fail ArgumentError, "The input argument (attributes) must be a hash in `Coinbase::Client::AddressReputationMetadata` initialize method"
      end

      # check to see if the attribute exists and convert string to symbol for hash key
      attributes = attributes.each_with_object({}) { |(k, v), h|
        if (!self.class.attribute_map.key?(k.to_sym))
          fail ArgumentError, "`#{k}` is not a valid attribute in `Coinbase::Client::AddressReputationMetadata`. Please check the name to make sure it's valid. List of attributes: " + self.class.attribute_map.keys.inspect
        end
        h[k.to_sym] = v
      }

      if attributes.key?(:'total_transactions')
        self.total_transactions = attributes[:'total_transactions']
      else
        self.total_transactions = nil
      end

      if attributes.key?(:'unique_days_active')
        self.unique_days_active = attributes[:'unique_days_active']
      else
        self.unique_days_active = nil
      end

      if attributes.key?(:'longest_active_streak')
        self.longest_active_streak = attributes[:'longest_active_streak']
      else
        self.longest_active_streak = nil
      end

      if attributes.key?(:'current_active_streak')
        self.current_active_streak = attributes[:'current_active_streak']
      else
        self.current_active_streak = nil
      end

      if attributes.key?(:'activity_period_days')
        self.activity_period_days = attributes[:'activity_period_days']
      else
        self.activity_period_days = nil
      end

      if attributes.key?(:'token_swaps_performed')
        self.token_swaps_performed = attributes[:'token_swaps_performed']
      else
        self.token_swaps_performed = nil
      end

      if attributes.key?(:'bridge_transactions_performed')
        self.bridge_transactions_performed = attributes[:'bridge_transactions_performed']
      else
        self.bridge_transactions_performed = nil
      end

      if attributes.key?(:'lend_borrow_stake_transactions')
        self.lend_borrow_stake_transactions = attributes[:'lend_borrow_stake_transactions']
      else
        self.lend_borrow_stake_transactions = nil
      end

      if attributes.key?(:'ens_contract_interactions')
        self.ens_contract_interactions = attributes[:'ens_contract_interactions']
      else
        self.ens_contract_interactions = nil
      end

      if attributes.key?(:'smart_contract_deployments')
        self.smart_contract_deployments = attributes[:'smart_contract_deployments']
      else
        self.smart_contract_deployments = nil
      end
    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      warn '[DEPRECATED] the `list_invalid_properties` method is obsolete'
      invalid_properties = Array.new
      if @total_transactions.nil?
        invalid_properties.push('invalid value for "total_transactions", total_transactions cannot be nil.')
      end

      if @unique_days_active.nil?
        invalid_properties.push('invalid value for "unique_days_active", unique_days_active cannot be nil.')
      end

      if @longest_active_streak.nil?
        invalid_properties.push('invalid value for "longest_active_streak", longest_active_streak cannot be nil.')
      end

      if @current_active_streak.nil?
        invalid_properties.push('invalid value for "current_active_streak", current_active_streak cannot be nil.')
      end

      if @activity_period_days.nil?
        invalid_properties.push('invalid value for "activity_period_days", activity_period_days cannot be nil.')
      end

      if @token_swaps_performed.nil?
        invalid_properties.push('invalid value for "token_swaps_performed", token_swaps_performed cannot be nil.')
      end

      if @bridge_transactions_performed.nil?
        invalid_properties.push('invalid value for "bridge_transactions_performed", bridge_transactions_performed cannot be nil.')
      end

      if @lend_borrow_stake_transactions.nil?
        invalid_properties.push('invalid value for "lend_borrow_stake_transactions", lend_borrow_stake_transactions cannot be nil.')
      end

      if @ens_contract_interactions.nil?
        invalid_properties.push('invalid value for "ens_contract_interactions", ens_contract_interactions cannot be nil.')
      end

      if @smart_contract_deployments.nil?
        invalid_properties.push('invalid value for "smart_contract_deployments", smart_contract_deployments cannot be nil.')
      end

      invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      warn '[DEPRECATED] the `valid?` method is obsolete'
      return false if @total_transactions.nil?
      return false if @unique_days_active.nil?
      return false if @longest_active_streak.nil?
      return false if @current_active_streak.nil?
      return false if @activity_period_days.nil?
      return false if @token_swaps_performed.nil?
      return false if @bridge_transactions_performed.nil?
      return false if @lend_borrow_stake_transactions.nil?
      return false if @ens_contract_interactions.nil?
      return false if @smart_contract_deployments.nil?
      true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          total_transactions == o.total_transactions &&
          unique_days_active == o.unique_days_active &&
          longest_active_streak == o.longest_active_streak &&
          current_active_streak == o.current_active_streak &&
          activity_period_days == o.activity_period_days &&
          token_swaps_performed == o.token_swaps_performed &&
          bridge_transactions_performed == o.bridge_transactions_performed &&
          lend_borrow_stake_transactions == o.lend_borrow_stake_transactions &&
          ens_contract_interactions == o.ens_contract_interactions &&
          smart_contract_deployments == o.smart_contract_deployments
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Integer] Hash code
    def hash
      [total_transactions, unique_days_active, longest_active_streak, current_active_streak, activity_period_days, token_swaps_performed, bridge_transactions_performed, lend_borrow_stake_transactions, ens_contract_interactions, smart_contract_deployments].hash
    end

    # Builds the object from hash
    # @param [Hash] attributes Model attributes in the form of hash
    # @return [Object] Returns the model itself
    def self.build_from_hash(attributes)
      return nil unless attributes.is_a?(Hash)
      attributes = attributes.transform_keys(&:to_sym)
      transformed_hash = {}
      openapi_types.each_pair do |key, type|
        if attributes.key?(attribute_map[key]) && attributes[attribute_map[key]].nil?
          transformed_hash["#{key}"] = nil
        elsif type =~ /\AArray<(.*)>/i
          # check to ensure the input is an array given that the attribute
          # is documented as an array but the input is not
          if attributes[attribute_map[key]].is_a?(Array)
            transformed_hash["#{key}"] = attributes[attribute_map[key]].map { |v| _deserialize($1, v) }
          end
        elsif !attributes[attribute_map[key]].nil?
          transformed_hash["#{key}"] = _deserialize(type, attributes[attribute_map[key]])
        end
      end
      new(transformed_hash)
    end

    # Deserializes the data based on type
    # @param string type Data type
    # @param string value Value to be deserialized
    # @return [Object] Deserialized data
    def self._deserialize(type, value)
      case type.to_sym
      when :Time
        Time.parse(value)
      when :Date
        Date.parse(value)
      when :String
        value.to_s
      when :Integer
        value.to_i
      when :Float
        value.to_f
      when :Boolean
        if value.to_s =~ /\A(true|t|yes|y|1)\z/i
          true
        else
          false
        end
      when :Object
        # generic object (usually a Hash), return directly
        value
      when /\AArray<(?<inner_type>.+)>\z/
        inner_type = Regexp.last_match[:inner_type]
        value.map { |v| _deserialize(inner_type, v) }
      when /\AHash<(?<k_type>.+?), (?<v_type>.+)>\z/
        k_type = Regexp.last_match[:k_type]
        v_type = Regexp.last_match[:v_type]
        {}.tap do |hash|
          value.each do |k, v|
            hash[_deserialize(k_type, k)] = _deserialize(v_type, v)
          end
        end
      else # model
        # models (e.g. Pet) or oneOf
        klass = Coinbase::Client.const_get(type)
        klass.respond_to?(:openapi_any_of) || klass.respond_to?(:openapi_one_of) ? klass.build(value) : klass.build_from_hash(value)
      end
    end

    # Returns the string representation of the object
    # @return [String] String presentation of the object
    def to_s
      to_hash.to_s
    end

    # to_body is an alias to to_hash (backward compatibility)
    # @return [Hash] Returns the object in the form of hash
    def to_body
      to_hash
    end

    # Returns the object in the form of hash
    # @return [Hash] Returns the object in the form of hash
    def to_hash
      hash = {}
      self.class.attribute_map.each_pair do |attr, param|
        value = self.send(attr)
        if value.nil?
          is_nullable = self.class.openapi_nullable.include?(attr)
          next if !is_nullable || (is_nullable && !instance_variable_defined?(:"@#{attr}"))
        end

        hash[param] = _to_hash(value)
      end
      hash
    end

    # Outputs non-array value in the form of hash
    # For object, use to_hash. Otherwise, just return the value
    # @param [Object] value Any valid value
    # @return [Hash] Returns the value in the form of hash
    def _to_hash(value)
      if value.is_a?(Array)
        value.compact.map { |v| _to_hash(v) }
      elsif value.is_a?(Hash)
        {}.tap do |hash|
          value.each { |k, v| hash[k] = _to_hash(v) }
        end
      elsif value.respond_to? :to_hash
        value.to_hash
      else
        value
      end
    end

  end

end
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
  # Represents an event triggered by a smart contract activity on the blockchain. Contains information about the function, transaction, block, and involved addresses.
  class SmartContractActivityEvent
    # Unique identifier for the webhook that triggered this event.
    attr_accessor :webhook_id

    # Type of event, in this case, an ERC-721 token transfer.
    attr_accessor :event_type

    # Blockchain network where the event occurred.
    attr_accessor :network

    # Name of the project this smart contract belongs to.
    attr_accessor :project_name

    # Name of the contract.
    attr_accessor :contract_name

    # Name of the function.
    attr_accessor :func

    # Signature of the function.
    attr_accessor :sig

    # First 4 bytes of the Transaction, a unique ID.
    attr_accessor :four_bytes

    # Address of the smart contract.
    attr_accessor :contract_address

    # Hash of the block containing the transaction.
    attr_accessor :block_hash

    # Number of the block containing the transaction.
    attr_accessor :block_number

    # Timestamp when the block was mined.
    attr_accessor :block_time

    # Hash of the transaction that triggered the event.
    attr_accessor :transaction_hash

    # Position of the transaction within the block.
    attr_accessor :transaction_index

    # Position of the event log within the transaction.
    attr_accessor :log_index

    # Address of the initiator in the transfer.
    attr_accessor :from

    # Address of the recipient in the transfer.
    attr_accessor :to

    # Amount of tokens transferred, typically in the smallest unit (e.g., wei for Ethereum).
    attr_accessor :value

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        :'webhook_id' => :'webhookId',
        :'event_type' => :'eventType',
        :'network' => :'network',
        :'project_name' => :'projectName',
        :'contract_name' => :'contractName',
        :'func' => :'func',
        :'sig' => :'sig',
        :'four_bytes' => :'fourBytes',
        :'contract_address' => :'contractAddress',
        :'block_hash' => :'blockHash',
        :'block_number' => :'blockNumber',
        :'block_time' => :'blockTime',
        :'transaction_hash' => :'transactionHash',
        :'transaction_index' => :'transactionIndex',
        :'log_index' => :'logIndex',
        :'from' => :'from',
        :'to' => :'to',
        :'value' => :'value'
      }
    end

    # Returns all the JSON keys this model knows about
    def self.acceptable_attributes
      attribute_map.values
    end

    # Attribute type mapping.
    def self.openapi_types
      {
        :'webhook_id' => :'String',
        :'event_type' => :'String',
        :'network' => :'String',
        :'project_name' => :'String',
        :'contract_name' => :'String',
        :'func' => :'String',
        :'sig' => :'String',
        :'four_bytes' => :'String',
        :'contract_address' => :'String',
        :'block_hash' => :'String',
        :'block_number' => :'Integer',
        :'block_time' => :'Time',
        :'transaction_hash' => :'String',
        :'transaction_index' => :'Integer',
        :'log_index' => :'Integer',
        :'from' => :'String',
        :'to' => :'String',
        :'value' => :'Integer'
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
        fail ArgumentError, "The input argument (attributes) must be a hash in `Coinbase::Client::SmartContractActivityEvent` initialize method"
      end

      # check to see if the attribute exists and convert string to symbol for hash key
      attributes = attributes.each_with_object({}) { |(k, v), h|
        if (!self.class.attribute_map.key?(k.to_sym))
          fail ArgumentError, "`#{k}` is not a valid attribute in `Coinbase::Client::SmartContractActivityEvent`. Please check the name to make sure it's valid. List of attributes: " + self.class.attribute_map.keys.inspect
        end
        h[k.to_sym] = v
      }

      if attributes.key?(:'webhook_id')
        self.webhook_id = attributes[:'webhook_id']
      end

      if attributes.key?(:'event_type')
        self.event_type = attributes[:'event_type']
      end

      if attributes.key?(:'network')
        self.network = attributes[:'network']
      end

      if attributes.key?(:'project_name')
        self.project_name = attributes[:'project_name']
      end

      if attributes.key?(:'contract_name')
        self.contract_name = attributes[:'contract_name']
      end

      if attributes.key?(:'func')
        self.func = attributes[:'func']
      end

      if attributes.key?(:'sig')
        self.sig = attributes[:'sig']
      end

      if attributes.key?(:'four_bytes')
        self.four_bytes = attributes[:'four_bytes']
      end

      if attributes.key?(:'contract_address')
        self.contract_address = attributes[:'contract_address']
      end

      if attributes.key?(:'block_hash')
        self.block_hash = attributes[:'block_hash']
      end

      if attributes.key?(:'block_number')
        self.block_number = attributes[:'block_number']
      end

      if attributes.key?(:'block_time')
        self.block_time = attributes[:'block_time']
      end

      if attributes.key?(:'transaction_hash')
        self.transaction_hash = attributes[:'transaction_hash']
      end

      if attributes.key?(:'transaction_index')
        self.transaction_index = attributes[:'transaction_index']
      end

      if attributes.key?(:'log_index')
        self.log_index = attributes[:'log_index']
      end

      if attributes.key?(:'from')
        self.from = attributes[:'from']
      end

      if attributes.key?(:'to')
        self.to = attributes[:'to']
      end

      if attributes.key?(:'value')
        self.value = attributes[:'value']
      end
    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      warn '[DEPRECATED] the `list_invalid_properties` method is obsolete'
      invalid_properties = Array.new
      invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      warn '[DEPRECATED] the `valid?` method is obsolete'
      true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          webhook_id == o.webhook_id &&
          event_type == o.event_type &&
          network == o.network &&
          project_name == o.project_name &&
          contract_name == o.contract_name &&
          func == o.func &&
          sig == o.sig &&
          four_bytes == o.four_bytes &&
          contract_address == o.contract_address &&
          block_hash == o.block_hash &&
          block_number == o.block_number &&
          block_time == o.block_time &&
          transaction_hash == o.transaction_hash &&
          transaction_index == o.transaction_index &&
          log_index == o.log_index &&
          from == o.from &&
          to == o.to &&
          value == o.value
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Integer] Hash code
    def hash
      [webhook_id, event_type, network, project_name, contract_name, func, sig, four_bytes, contract_address, block_hash, block_number, block_time, transaction_hash, transaction_index, log_index, from, to, value].hash
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

=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.5.0

=end

require 'date'
require 'time'

module Coinbase::Client
  # An event representing a signature creation.
  class SignatureCreationEvent
    # The ID of the seed that the server-signer should create the signature for
    attr_accessor :seed_id

    # The ID of the wallet the signature is for
    attr_accessor :wallet_id

    # The ID of the user that the wallet belongs to
    attr_accessor :wallet_user_id

    # The ID of the address the transfer belongs to
    attr_accessor :address_id

    # The index of the address that the server-signer should sign with
    attr_accessor :address_index

    # The payload that the server-signer should sign
    attr_accessor :signing_payload

    attr_accessor :transaction_type

    # The ID of the transaction that the server-signer should sign
    attr_accessor :transaction_id

    class EnumAttributeValidator
      attr_reader :datatype
      attr_reader :allowable_values

      def initialize(datatype, allowable_values)
        @allowable_values = allowable_values.map do |value|
          case datatype.to_s
          when /Integer/i
            value.to_i
          when /Float/i
            value.to_f
          else
            value
          end
        end
      end

      def valid?(value)
        !value || allowable_values.include?(value)
      end
    end

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        :'seed_id' => :'seed_id',
        :'wallet_id' => :'wallet_id',
        :'wallet_user_id' => :'wallet_user_id',
        :'address_id' => :'address_id',
        :'address_index' => :'address_index',
        :'signing_payload' => :'signing_payload',
        :'transaction_type' => :'transaction_type',
        :'transaction_id' => :'transaction_id'
      }
    end

    # Returns all the JSON keys this model knows about
    def self.acceptable_attributes
      attribute_map.values
    end

    # Attribute type mapping.
    def self.openapi_types
      {
        :'seed_id' => :'String',
        :'wallet_id' => :'String',
        :'wallet_user_id' => :'String',
        :'address_id' => :'String',
        :'address_index' => :'Integer',
        :'signing_payload' => :'String',
        :'transaction_type' => :'TransactionType',
        :'transaction_id' => :'String'
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
        fail ArgumentError, "The input argument (attributes) must be a hash in `Coinbase::Client::SignatureCreationEvent` initialize method"
      end

      # check to see if the attribute exists and convert string to symbol for hash key
      attributes = attributes.each_with_object({}) { |(k, v), h|
        if (!self.class.attribute_map.key?(k.to_sym))
          fail ArgumentError, "`#{k}` is not a valid attribute in `Coinbase::Client::SignatureCreationEvent`. Please check the name to make sure it's valid. List of attributes: " + self.class.attribute_map.keys.inspect
        end
        h[k.to_sym] = v
      }

      if attributes.key?(:'seed_id')
        self.seed_id = attributes[:'seed_id']
      else
        self.seed_id = nil
      end

      if attributes.key?(:'wallet_id')
        self.wallet_id = attributes[:'wallet_id']
      else
        self.wallet_id = nil
      end

      if attributes.key?(:'wallet_user_id')
        self.wallet_user_id = attributes[:'wallet_user_id']
      else
        self.wallet_user_id = nil
      end

      if attributes.key?(:'address_id')
        self.address_id = attributes[:'address_id']
      else
        self.address_id = nil
      end

      if attributes.key?(:'address_index')
        self.address_index = attributes[:'address_index']
      else
        self.address_index = nil
      end

      if attributes.key?(:'signing_payload')
        self.signing_payload = attributes[:'signing_payload']
      else
        self.signing_payload = nil
      end

      if attributes.key?(:'transaction_type')
        self.transaction_type = attributes[:'transaction_type']
      else
        self.transaction_type = nil
      end

      if attributes.key?(:'transaction_id')
        self.transaction_id = attributes[:'transaction_id']
      else
        self.transaction_id = nil
      end
    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      warn '[DEPRECATED] the `list_invalid_properties` method is obsolete'
      invalid_properties = Array.new
      if @seed_id.nil?
        invalid_properties.push('invalid value for "seed_id", seed_id cannot be nil.')
      end

      if @wallet_id.nil?
        invalid_properties.push('invalid value for "wallet_id", wallet_id cannot be nil.')
      end

      if @wallet_user_id.nil?
        invalid_properties.push('invalid value for "wallet_user_id", wallet_user_id cannot be nil.')
      end

      if @address_id.nil?
        invalid_properties.push('invalid value for "address_id", address_id cannot be nil.')
      end

      if @address_index.nil?
        invalid_properties.push('invalid value for "address_index", address_index cannot be nil.')
      end

      if @signing_payload.nil?
        invalid_properties.push('invalid value for "signing_payload", signing_payload cannot be nil.')
      end

      if @transaction_type.nil?
        invalid_properties.push('invalid value for "transaction_type", transaction_type cannot be nil.')
      end

      if @transaction_id.nil?
        invalid_properties.push('invalid value for "transaction_id", transaction_id cannot be nil.')
      end

      invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      warn '[DEPRECATED] the `valid?` method is obsolete'
      return false if @seed_id.nil?
      return false if @wallet_id.nil?
      return false if @wallet_user_id.nil?
      return false if @address_id.nil?
      return false if @address_index.nil?
      return false if @signing_payload.nil?
      return false if @transaction_type.nil?
      return false if @transaction_id.nil?
      true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          seed_id == o.seed_id &&
          wallet_id == o.wallet_id &&
          wallet_user_id == o.wallet_user_id &&
          address_id == o.address_id &&
          address_index == o.address_index &&
          signing_payload == o.signing_payload &&
          transaction_type == o.transaction_type &&
          transaction_id == o.transaction_id
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Integer] Hash code
    def hash
      [seed_id, wallet_id, wallet_user_id, address_id, address_index, signing_payload, transaction_type, transaction_id].hash
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

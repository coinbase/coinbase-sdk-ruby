=begin
#Coinbase Platform API

#This is the OpenAPI 3.0 specification for the Coinbase Platform APIs, used in conjunction with the Coinbase Platform SDKs.

The version of the OpenAPI document: 0.0.1-alpha
Contact: yuga.cohler@coinbase.com
Generated by: https://openapi-generator.tech
Generator version: 7.7.0

=end

require 'date'
require 'time'

module Coinbase::Client
  class Network
    attr_accessor :id

    # The human-readable name of the blockchain network
    attr_accessor :display_name

    # The chain ID of the blockchain network
    attr_accessor :chain_id

    # The protocol family of the blockchain network
    attr_accessor :protocol_family

    # Whether the network is a testnet or not
    attr_accessor :is_testnet

    attr_accessor :native_asset

    attr_accessor :feature_set

    # The BIP44 path prefix for the network
    attr_accessor :address_path_prefix

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
        :'id' => :'id',
        :'display_name' => :'display_name',
        :'chain_id' => :'chain_id',
        :'protocol_family' => :'protocol_family',
        :'is_testnet' => :'is_testnet',
        :'native_asset' => :'native_asset',
        :'feature_set' => :'feature_set',
        :'address_path_prefix' => :'address_path_prefix'
      }
    end

    # Returns all the JSON keys this model knows about
    def self.acceptable_attributes
      attribute_map.values
    end

    # Attribute type mapping.
    def self.openapi_types
      {
        :'id' => :'NetworkIdentifier',
        :'display_name' => :'String',
        :'chain_id' => :'Integer',
        :'protocol_family' => :'String',
        :'is_testnet' => :'Boolean',
        :'native_asset' => :'Asset',
        :'feature_set' => :'FeatureSet',
        :'address_path_prefix' => :'String'
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
        fail ArgumentError, "The input argument (attributes) must be a hash in `Coinbase::Client::Network` initialize method"
      end

      # check to see if the attribute exists and convert string to symbol for hash key
      attributes = attributes.each_with_object({}) { |(k, v), h|
        if (!self.class.attribute_map.key?(k.to_sym))
          fail ArgumentError, "`#{k}` is not a valid attribute in `Coinbase::Client::Network`. Please check the name to make sure it's valid. List of attributes: " + self.class.attribute_map.keys.inspect
        end
        h[k.to_sym] = v
      }

      if attributes.key?(:'id')
        self.id = attributes[:'id']
      else
        self.id = nil
      end

      if attributes.key?(:'display_name')
        self.display_name = attributes[:'display_name']
      else
        self.display_name = nil
      end

      if attributes.key?(:'chain_id')
        self.chain_id = attributes[:'chain_id']
      else
        self.chain_id = nil
      end

      if attributes.key?(:'protocol_family')
        self.protocol_family = attributes[:'protocol_family']
      else
        self.protocol_family = nil
      end

      if attributes.key?(:'is_testnet')
        self.is_testnet = attributes[:'is_testnet']
      else
        self.is_testnet = nil
      end

      if attributes.key?(:'native_asset')
        self.native_asset = attributes[:'native_asset']
      else
        self.native_asset = nil
      end

      if attributes.key?(:'feature_set')
        self.feature_set = attributes[:'feature_set']
      else
        self.feature_set = nil
      end

      if attributes.key?(:'address_path_prefix')
        self.address_path_prefix = attributes[:'address_path_prefix']
      end
    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      warn '[DEPRECATED] the `list_invalid_properties` method is obsolete'
      invalid_properties = Array.new
      if @id.nil?
        invalid_properties.push('invalid value for "id", id cannot be nil.')
      end

      if @display_name.nil?
        invalid_properties.push('invalid value for "display_name", display_name cannot be nil.')
      end

      if @chain_id.nil?
        invalid_properties.push('invalid value for "chain_id", chain_id cannot be nil.')
      end

      if @protocol_family.nil?
        invalid_properties.push('invalid value for "protocol_family", protocol_family cannot be nil.')
      end

      if @is_testnet.nil?
        invalid_properties.push('invalid value for "is_testnet", is_testnet cannot be nil.')
      end

      if @native_asset.nil?
        invalid_properties.push('invalid value for "native_asset", native_asset cannot be nil.')
      end

      if @feature_set.nil?
        invalid_properties.push('invalid value for "feature_set", feature_set cannot be nil.')
      end

      invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      warn '[DEPRECATED] the `valid?` method is obsolete'
      return false if @id.nil?
      return false if @display_name.nil?
      return false if @chain_id.nil?
      return false if @protocol_family.nil?
      protocol_family_validator = EnumAttributeValidator.new('String', ["evm", "unknown_default_open_api"])
      return false unless protocol_family_validator.valid?(@protocol_family)
      return false if @is_testnet.nil?
      return false if @native_asset.nil?
      return false if @feature_set.nil?
      true
    end

    # Custom attribute writer method checking allowed values (enum).
    # @param [Object] protocol_family Object to be assigned
    def protocol_family=(protocol_family)
      validator = EnumAttributeValidator.new('String', ["evm", "unknown_default_open_api"])
      unless validator.valid?(protocol_family)
        fail ArgumentError, "invalid value for \"protocol_family\", must be one of #{validator.allowable_values}."
      end
      @protocol_family = protocol_family
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          id == o.id &&
          display_name == o.display_name &&
          chain_id == o.chain_id &&
          protocol_family == o.protocol_family &&
          is_testnet == o.is_testnet &&
          native_asset == o.native_asset &&
          feature_set == o.feature_set &&
          address_path_prefix == o.address_path_prefix
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Integer] Hash code
    def hash
      [id, display_name, chain_id, protocol_family, is_testnet, native_asset, feature_set, address_path_prefix].hash
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

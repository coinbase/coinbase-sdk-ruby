# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'coinbase-sdk'
  spec.version       = '0.0.1'
  spec.authors       = ['Yuga Cohler']

  spec.summary       = 'Coinbase Ruby SDK'
  spec.homepage      = 'https://github.com/coinbase/coinbase-sdk-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'bigdecimal'
  spec.add_dependency 'dotenv'
  spec.add_dependency 'eth'
  spec.add_dependency 'jimson'
  spec.add_dependency 'money-tree'
  spec.add_dependency 'securerandom'
end

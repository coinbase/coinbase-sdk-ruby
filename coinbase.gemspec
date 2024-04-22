# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'coinbase-sdk'
  spec.version       = '0.0.1'
  spec.authors       = ['Yuga Cohler']
  spec.files         = Dir['lib/**/*.rb']
  spec.summary       = 'Coinbase Ruby SDK'

  spec.description   = 'Coinbase Ruby SDK for accessing Coinbase Platform APIs'
  spec.email         = 'yuga.cohler@coinbase.com'
  spec.homepage      = 'https://github.com/coinbase/coinbase-sdk-ruby'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_runtime_dependency 'bigdecimal'
  spec.add_runtime_dependency 'eth'
  spec.add_runtime_dependency 'jimson'
  spec.add_runtime_dependency 'jwt'
  spec.add_runtime_dependency 'money-tree'
  spec.add_runtime_dependency 'openssl'
  spec.add_runtime_dependency 'securerandom'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  # Pin to a specific version of RuboCop to ensure consistent linting.
  spec.add_development_dependency 'rubocop', '1.63.1'
  # Pin to a specific version of YARD to ensure consistent documentation generation.
  spec.add_development_dependency 'yard', '0.9.36'
end

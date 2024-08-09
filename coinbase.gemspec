# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'coinbase-sdk'
  spec.version = '0.0.14'
  spec.authors = ['Yuga Cohler']
  spec.files = Dir['lib/**/*.rb']
  spec.summary = 'Coinbase Ruby SDK'

  spec.description = 'Coinbase Ruby SDK for accessing Coinbase Platform APIs'
  spec.email = 'yuga.cohler@coinbase.com'
  spec.homepage = 'https://github.com/coinbase/coinbase-sdk-ruby'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_runtime_dependency 'bigdecimal'
  spec.add_runtime_dependency 'eth'
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday-multipart'
  spec.add_runtime_dependency 'faraday-retry'
  spec.add_runtime_dependency 'jwt'
  spec.add_runtime_dependency 'marcel'
  spec.add_runtime_dependency 'money-tree'

  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '1.63.1' # Pin to ensure consistent linting
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard', '0.9.36' # Pin to ensure consistent documentation generation
  spec.add_development_dependency 'yard-markdown'
end

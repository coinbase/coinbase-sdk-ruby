require 'dotenv'
Dotenv.load

describe Coinbase do
  describe 'v0.0.2 SDK' do
    it 'behaves as expected' do
      api_key_name = ENV['API_KEY_NAME'].gsub(' ', "\n")
      api_key_private_key = ENV['API_KEY_PRIVATE_KEY'].gsub(' ', "\n")
      Coinbase.init(api_key_name, api_key_private_key)

      puts "Fetching default user..."
      puts "TEST_VAR is: #{ENV['TEST_VAR']}"
      u = Coinbase.default_user
    end
  end
end

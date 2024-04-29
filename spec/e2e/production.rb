require 'dotenv'
Dotenv.load

describe Coinbase do
  describe 'v0.0.2 SDK' do
    it 'behaves as expected' do
      Coinbase.init(ENV['API_KEY_NAME'], ENV['API_KEY_PRIVATE_KEY']).gsub('\n', "\n"))

      puts "Fetching default user..."
      u = Coinbase.default_user
    end
  end
end

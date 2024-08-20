# frozen_string_literal: true

require_relative 'asset'
require_relative 'network'

module Coinbase
  # The number of decimal places in Gwei.
  GWEI_DECIMALS = 9

  # The default page limit for paginated API requests.
  DEFAULT_PAGE_LIMIT = 100
end

# frozen_string_literal: true

module Coinbase
  # A module of helper methods for paginating through resources.
  module Pagination
    def self.enumerate(fetcher, &build_resource)
      Enumerator.new do |yielder|
        page = nil

        loop do
          response = Coinbase.call_api { fetcher.call(page) }

          break if response.data.empty?

          response.data.each do |model|
            yielder << build_resource.call(model)
          end

          break unless response.has_more

          page = response.next_page
        end
      end
    end
  end
end

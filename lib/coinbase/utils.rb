# frozen_string_literal: true

module Coinbase
  # Converts a Coinbase::Client::AddressBalanceList to a BalanceMap.
  # @param address_balance_list [Coinbase::Client::AddressBalanceList] The AddressBalanceList to convert
  # @return [BalanceMap] The converted BalanceMap
  def self.to_balance_map(address_balance_list)
    balances = {}

    address_balance_list.data.each do |balance|
      asset_id = Coinbase.to_sym(balance.asset.asset_id.downcase)
      amount = if asset_id == :eth
                 BigDecimal(balance.amount) / BigDecimal(Coinbase::WEI_PER_ETHER)
               else
                 BigDecimal(balance.amount)
               end
      balances[asset_id] = amount
    end

    BalanceMap.new(balances)
  end
end

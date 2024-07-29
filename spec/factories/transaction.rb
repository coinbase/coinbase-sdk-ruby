FactoryBot.define do
  factory :transaction_model, class: Coinbase::Client::Transaction do
    status { 'pending' }
    from_address_id { build(:key).address.to_s }
    unsigned_payload { '' }
  end

  factory :transaction do
    amount { 1.5 }
    currency { 'BTC' }
    recipient { '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy' }
    sender { '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa' }
    status { 'pending' }
    type { 'send' }
    hash { 'f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16' }
    network { 'bitcoin' }
  end
end

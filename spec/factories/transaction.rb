# frozen_string_literal: true

FactoryBot.define do
  factory :transaction_model, class: Coinbase::Client::Transaction do
    transient do
      key { build(:key) }
    end

    status { 'pending' }
    from_address_id { key.address.to_s }
    unsigned_payload do \
      '7b2274797065223a22307832222c22636861696e4964223a2230783134613334222c226e6f6e6365223a22307830' \
        '222c22746f223a2230786533313730363564653739356566626163373163663030313134633732353262666364' \
        '3233633239222c22676173223a22307835323038222c226761735072696365223a6e756c6c2c226d6178507269' \
        '6f72697479466565506572476173223a2230786634323430222c226d6178466565506572476173223a22307866' \
        '34343265222c2276616c7565223a2230783931383465373261303030222c22696e707574223a223078222c2261' \
        '63636573734c697374223a5b5d2c2276223a22307830222c2272223a22307830222c2273223a22307830222c22' \
        '79506172697479223a22307830222c2268617368223a2230783232373461653832663838623664303334393066' \
        '3561663235343534383764633862316239623538646461303336326134316436313339346136346662646634227d'
    end

    trait :signed do
      status { 'signed' }

      signed_payload do \
        '02f87183014a3480830f4240830f442e82520894e317065de795efbac71cf00114c7252bfcd23c298609184e72a0' \
          '0080c080a0eab79ad9a2933fcea4acc375ed9cffb9345623f9f377c8afca59c368e5a6a20da071f32cafa36a49' \
          '5531dd76a4edac70280eda4a18bdcbbcc5496c41fe884b6aba'
      end
    end

    trait :broadcasted do
      signed
      status { 'broadcast' }
      transaction_hash { '0xdea671372a8fff080950d09ad5994145a661c8e95a9216ef34772a19191b5690' }
      transaction_link { "https://sepolia.basescan.org/tx/#{transaction_hash}" }
    end

    trait :completed do
      broadcasted
      status { 'complete' }
    end

    trait :failed do
      broadcasted
      status { 'failed' }
    end
  end

  factory :transaction, class: Coinbase::Transaction do
    initialize_with { new(model) }
    model { build(:transaction_model) }
  end
end

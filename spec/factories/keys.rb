# frozen_string_literal: true

FactoryBot.define do
  factory :key, class: Eth::Key do
    initialize_with { new(priv: priv) }

    priv { '0233b43978845c03783510106941f42370e0f11022b0c3b717c0791d046f4536' }
  end
end

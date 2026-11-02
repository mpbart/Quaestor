# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { "test.email#{SecureRandom.uuid}@email.com" }
    password { SecureRandom.uuid }

    trait :member do
      association :owner, factory: :user
    end
  end
end

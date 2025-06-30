# frozen_string_literal: true

FactoryBot.define do
  factory :balance do
    account

    created_at { Time.current }
    amount { 100 }
  end
end

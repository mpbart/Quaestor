# frozen_string_literal: true

FactoryBot.define do
  factory :transaction_rule do
    id { SecureRandom.uuid }
    field_name_to_replace { 'plaid_category_id' }
    replacement_value { PlaidCategory.first.id }
  end
end

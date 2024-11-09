# frozen_string_literal: true

FactoryBot.define do
  factory :transaction_rule do
    id { SecureRandom.uuid }
    field_replacement_mappings { { category_id: PlaidCategory.first.id } }
  end
end

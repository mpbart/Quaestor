# frozen_string_literal: true

FactoryBot.define do
  factory :rule_criteria, class: RuleCriteria do
    association :transaction_rule

    field_name { 'description' }
    field_qualifier { '==' }
    value_comparator { 'venmo' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :plaid_category do
    primary_category { 'GENERAL_GOODS' }
    detailed_category { 'GENERAL_GOODS_PIZZA' }
  end
end

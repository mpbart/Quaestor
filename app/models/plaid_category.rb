# frozen_string_literal: true

class PlaidCategory < ActiveRecord::Base
  # TODO: This should be replaced when automatic rules for exlusions are implemented
  EXCLUDED_CATEGORIES = %w[TRANSFER_IN_ACCOUNT_TRANSFER
                           TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS
                           TRANSFER_OUT_ACCOUNT_TRANSFER
                           LOAN_PAYMENTS_CREDIT_CARD_PAYMENT
                           EXCLUDED_EXCLUDED].freeze
  RECURRING_CATEGORIES = %w[LOAN_PAYMENTS_CAR_PAYMENT LOAN_PAYMENTS_MORTGAGE_PAYMENT
                            FOOD_AND_DRINK_GROCERIES GENERAL_SERVICES_INSURANCE
                            RENT_AND_UTILITIES_GAS_AND_ELECTRICITY
                            RENT_AND_UTILITIES_INTERNET_AND_CABLE
                            RENT_AND_UTILITIES_TELEPHONE
                            RENT_AND_UTILITIES_WATER INCOME_WAGES
                            INCOME_DIVIDENDS INCOME_INTEREST_EARNED].freeze

  def self.grouped_by_top_level
    @grouped_by_top_level ||= PlaidCategory.all.group_by(&:primary_category)
  end

  def self.top_level_records
    @top_level_records ||= select(:primary_category).distinct.to_a
  end

  def self.category_children(top_level_key)
    grouped_by_top_level[top_level_key]
  end

  def children
    PlaidCategory.grouped_by_top_level[primary_category]
  end

  # Get all categories that match the given key
  # Note: that this assumes that keys are passed in hierarchical order
  def self.all_matching_categories(key:)
    categories = grouped_by_top_level[key.shift]

    return categories unless key

    categories.select { |c| c.hierarchy.include?(key.last) }
  end
end

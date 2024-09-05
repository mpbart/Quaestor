# frozen_string_literal: true

module FinanceManager
  module Transaction
    class Calculations
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def income_by_source(start_date, end_date)
        user.transactions.joins(:plaid_category)
            .within_days(start_date, end_date)
            .pluck(:amount, :primary_category, :detailed_category)
            .filter { |t| t[1] == 'INCOME' && !PlaidCategory::EXCLUDED_CATEGORIES.include?(t[2]) }
            .group_by { |t| t[1] }
      end

      def expenses_by_source(start_date, end_date)
        user.transactions.joins(:plaid_category)
            .within_days(start_date, end_date)
            .pluck(:amount, :primary_category, :detailed_category)
            .filter { |t| t[1] != 'INCOME' && !PlaidCategory::EXCLUDED_CATEGORIES.include?(t[2]) }
            .group_by { |t| t[1] }
      end

      def total_amount(grouped_transactions)
        grouped_transactions.sum { |_k, v| v.sum(&:first) }.abs.round(2)
      end

      def recurring(grouped_transactions)
        grouped_transactions.map do |k, v|
          [k, v.filter { |arr| PlaidCategory::RECURRING_CATEGORIES.include?(arr[2]) }]
        end
      end

      def non_recurring(grouped_transactions)
        grouped_transactions.map do |k, v|
          [k, v.filter { |arr| !PlaidCategory::RECURRING_CATEGORIES.include?(arr[2]) }]
        end
      end
    end
  end
end

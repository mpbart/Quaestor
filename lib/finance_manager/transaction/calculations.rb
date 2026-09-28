# frozen_string_literal: true

module FinanceManager
  module Transaction
    class Calculations
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def income_by_source(start_date, end_date)
        income_transactions(start_date, end_date)
          .pluck(:amount, :primary_category, :detailed_category)
          .group_by { |t| t[1] }
      end

      def expenses_by_source(start_date, end_date)
        expense_transactions(start_date, end_date)
          .pluck(:amount, :primary_category, :detailed_category)
          .group_by { |t| t[1] }
      end

      def income_transactions(start_date, end_date)
        user.transactions.joins(:plaid_category)
            .within_days(start_date, end_date)
            .where("plaid_categories.primary_category = 'INCOME' AND plaid_categories.detailed_category NOT IN (?)", PlaidCategory::EXCLUDED_CATEGORIES)
      end

      def expense_transactions(start_date, end_date)
        user.transactions.joins(:plaid_category)
            .within_days(start_date, end_date)
            .where("plaid_categories.primary_category != 'INCOME' AND plaid_categories.detailed_category NOT IN (?)", PlaidCategory::EXCLUDED_CATEGORIES)
      end

      def total_amount(grouped_transactions)
        grouped_transactions.sum { |_k, v| v.sum(&:first) }.abs.round(2)
      end

      def recurring(transactions)
        transactions.joins(:plaid_category)
                    .where(plaid_categories: { detailed_category: PlaidCategory::RECURRING_CATEGORIES })
      end

      def non_recurring(transactions)
        transactions.joins(:plaid_category)
                    .where.not(plaid_categories: { detailed_category: PlaidCategory::RECURRING_CATEGORIES })
      end
    end
  end
end

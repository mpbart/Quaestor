# frozen_string_literal: true

require 'finance_manager/rules/scalar'
require 'finance_manager/rules/repository'

module FinanceManager
  module Rules
    class Runner
      extend FinanceManager::Rules::Repository

      register_rule_field 'description',       FinanceManager::Rules::Scalar::Description
      register_rule_field 'plaid_category_id', FinanceManager::Rules::Scalar::CategoryId
      register_rule_field 'amount',            FinanceManager::Rules::Scalar::Amount
      register_rule_field 'merchant_name',     FinanceManager::Rules::Scalar::MerchantName

      def self.run_all_rules(transaction)
        TransactionRule.all.each do |rule|
          transaction = run_rule(transaction, rule)
        end

        transaction
      end

      def self.run_rule(transaction, rule)
        if rule.rule_criteria.all? { |c| matches_criteria?(c, transaction) }
          rule.field_replacement_mappings.each do |field_name, new_value|
            transaction = apply_transformation(field_name, new_value, transaction)
          end
        end

        transaction
      end
    end
  end
end

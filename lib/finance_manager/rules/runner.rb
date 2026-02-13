# frozen_string_literal: true

require 'finance_manager/rules/scalar'
require 'finance_manager/rules/repository'
require_relative '../../finance_manager/transaction' # Add this line

module FinanceManager
  module Rules
    class Runner
      extend FinanceManager::Rules::Repository

      register_rule_field 'description',       FinanceManager::Rules::Scalar::Description
      register_rule_field 'plaid_category_id', FinanceManager::Rules::Scalar::Category
      register_rule_field 'amount',            FinanceManager::Rules::Scalar::Amount
      register_rule_field 'merchant_name',     FinanceManager::Rules::Scalar::MerchantName
      register_rule_field 'account_id',        FinanceManager::Rules::Scalar::Account
      register_rule_field 'label_id',          FinanceManager::Rules::Scalar::Label

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

          return transaction if transaction.pending

          # New splitting logic
          if rule.split_category_id.present? && rule.split_amount.present?
            new_transaction_details = {
              amount:            rule.split_amount,
              plaid_category_id: rule.split_category_id
            }
            new_transaction_details[:description] = rule.split_description if rule.split_description.present?
            new_transaction_details[:merchant_name] = rule.split_merchant_name if rule.split_merchant_name.present?
            new_transaction_details[:label_ids] = rule.split_labels if rule.split_labels.present?

            FinanceManager::Transaction.split!(transaction, new_transaction_details)
          end
        end

        transaction
      end
    end
  end
end

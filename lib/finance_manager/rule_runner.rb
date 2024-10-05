# frozen_string_literal: true

module FinanceManager
  module RuleRunner
    class Transaction
      class FieldNameNotImplemented < StandardError; end

      def self.run_all_rules(transaction)
        TransactionRule.all.each do |rule|
          transaction = run_rule(transaction, rule)
        end

        transaction
      end

      def self.run_rule(transaction, rule)
        rule_result = rule.rule_criteria.all? do |criteria|
          transaction.send(criteria.field_name)
                     .send(
                       criteria.field_qualifier,
                       map_field_to_type(criteria.field_name, criteria.value_comparator)
                     )
        end

        transaction.send("#{rule.field_name_to_replace}=", rule.replacement_value) if rule_result

        transaction
      end

      def self.map_field_to_type(field_name, field_value)
        case field_name
        when 'description', 'merchant_name'
          field_value.to_s
        when 'amount'
          field_value.to_f
        when 'plaid_category_id'
          field_value.to_i
        else
          raise RuleFieldNotImplementedError, "rule for field name #{field_name} not implemented"
        end
      end
    end
  end
end

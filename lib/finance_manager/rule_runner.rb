# frozen_string_literal: true

module FinanceManager
  module RuleRunner
    class Transaction
      class FieldNameNotImplemented < StandardError; end
      class FieldQualifierNotImplemented < StandardError; end

      def self.run_all_rules(transaction)
        TransactionRule.all.each do |rule|
          transaction = run_rule(transaction, rule)
        end

        transaction
      end

      def self.run_rule(transaction, rule)
        rule_result = rule.rule_criteria.all? do |criteria|
          original_value = transaction.send(criteria.field_name)
          comparison_value = typecast_raw_value(criteria.field_name, criteria.value_comparator)
          passes_rule?(original_value, criteria.field_qualifier, comparison_value)
        end

        if rule_result
          Rails.logger.info("Custom Rule fired for rule ID #{rule.id}")
          rule.field_replacement_mappings.each do |field_name, new_value|
            transaction.send("#{field_name}=", new_value)
          end
        end

        transaction
      end

      def self.typecast_raw_value(field_name, field_value)
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

      def self.passes_rule?(value, qualifier, value_comparator)
        case qualifier
        when '<', '>', '=='
          value.send(qualifier, value_comparator)
        when 'contains'
          value.downcase.include?(value_comparator)
        else
          raise FieldQualifierNotImplemented,
                "field qualifier #{qualifier} not implemented for rule"
        end
      end
    end
  end
end

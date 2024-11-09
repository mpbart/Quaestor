# frozen_string_literal: true

module FinanceManager
  module Rules
    module Repository
      class FieldNameNotImplementedError < StandardError; end

      def register_rule_field(field_name, rule_klass)
        @rules ||= {}
        @rules[field_name] = rule_klass
      end

      def matches_criteria?(criteria, transaction)
        rule_klass = @rules.fetch(criteria.field_name) do
          raise FieldNameNotImplementedError,
                "Field name #{criteria.field_name} does not have a rule registered!"
        end
        rule_klass.passes_rule?(transaction, criteria)
      end

      def apply_transformation(field_name, new_value, transaction)
        klass = @rules.fetch(field_name)
        parts = klass.transaction_field.split('.')
        parts[0...-1]
          .inject(transaction) { |obj, method| obj.send(method) }
          .send("#{parts.last}=", klass.map_value(new_value))

        transaction
      end
    end
  end
end

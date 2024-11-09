# frozen_string_literal: true

module FinanceManager
  module Rules
    module Scalar
      class Base
        def self.map_qualifier(qualifier)
          case qualifier
          when 'contains'
            'include?'
          else
            qualifier
          end
        end

        def self.map_value(value)
          value
        end
      end

      class Description < Base
        def self.passes_rule?(transaction, criteria)
          transaction.name.downcase.send(
            map_qualifier(criteria.field_qualifier),
            criteria.value_comparator.to_s.downcase
          )
        end

        def self.transaction_field
          'name'
        end
      end

      class CategoryId < Base
        def self.passes_rule?(transaction, criteria)
          transaction.personal_finance_category.detailed.send(
            criteria.field_qualifier,
            map_value(criteria.value_comparator)
          )
        end

        def self.transaction_field
          'personal_finance_category.detailed'
        end

        def self.map_value(value)
          PlaidCategory.find(value).detailed_category
        end
      end

      class Amount < Base
        def self.passes_rule?(transaction, criteria)
          transaction.amount.send(
            criteria.field_qualifier,
            criteria.value_comparator.to_f
          )
        end

        def self.transaction_field
          'amount'
        end
      end

      class MerchantName < Base
        def self.passes_rule?(transaction, criteria)
          transaction.merchant_name.downcase.send(
            map_qualifier(criteria.field_qualifier),
            criteria.value_comparator.to_s.downcase
          )
        end

        def self.transaction_field
          'merchant_name'
        end
      end
    end
  end
end

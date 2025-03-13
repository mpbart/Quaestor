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
          transaction.description.downcase.send(
            map_qualifier(criteria.field_qualifier),
            criteria.value_comparator.to_s.downcase
          )
        end

        def self.transaction_field
          'description'
        end
      end

      class Category < Base
        def self.passes_rule?(transaction, criteria)
          transaction.plaid_category.detailed_category.send(
            criteria.field_qualifier,
            map_value(criteria.value_comparator)
          )
        end

        def self.transaction_field
          'plaid_category_id'
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

      class Account < Base
        def self.passes_rule?(transaction, criteria)
          map_value(transaction.account_id).send(
            criteria.field_qualifier,
            criteria.value_comparator.to_i
          )
        end

        def self.transaction_field
          'account.id'
        end

        def self.map_value(value)
          ::Account.find_by(plaid_identifier: value)&.id
        end
      end

      class Label < Base
        # Labels are not used as rule criteria
        def self.passes_rule?(_transaction, _criteria)
          false
        end

        def self.transaction_field
          'label_ids'
        end

        def self.map_value(value)
          [::Label.find(value).id]
        end
      end
    end
  end
end

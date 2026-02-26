# frozen_string_literal: true

class TransactionRule < ActiveRecord::Base
  has_many :rule_criteria, class_name: 'RuleCriteria'
  belongs_to :split_category, class_name: 'PlaidCategory', foreign_key: 'split_category_id', optional: true
end

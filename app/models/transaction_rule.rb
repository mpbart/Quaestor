# frozen_string_literal: true

class TransactionRule < ActiveRecord::Base
  has_many :rule_criteria, class_name: 'RuleCriteria'
end

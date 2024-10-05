# frozen_string_literal: true

class RuleCriteria < ActiveRecord::Base
  self.table_name = 'rule_criteria'
  belongs_to :transaction_rule
end

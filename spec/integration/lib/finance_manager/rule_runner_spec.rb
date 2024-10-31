# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/rule_runner'

RSpec.describe FinanceManager::RuleRunner::Transaction do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:plaid_category) do
    create(
      :plaid_category,
      primary_category:  'original category',
      detailed_category: 'original category detailed'
    )
  end
  let(:transaction) do
    create(
      :transaction,
      user:           user,
      account:        account,
      description:    'venmo',
      amount:         90.0,
      merchant_name:  'merchant name',
      plaid_category: plaid_category
    )
  end
  let(:rule1) do
    create(
      :transaction_rule,
      field_replacement_mappings: { description: 'New Description' }
    )
  end
  let!(:rule_criteria1) do
    create(
      :rule_criteria,
      transaction_rule: rule1,
      field_name:       'amount',
      field_qualifier:  '<',
      value_comparator: 100
    )
  end
  let!(:rule_criteria2) do
    create(
      :rule_criteria,
      transaction_rule: rule1,
      field_name:       'plaid_category_id',
      field_qualifier:  '==',
      value_comparator: rule_criteria_plaid_category_id
    )
  end
  let(:rule_criteria_plaid_category_id) { plaid_category.id }

  subject(:run_rules) { described_class.run_all_rules(transaction) }

  context 'when all rule criteria are true' do
    it 'updates the transaction' do
      expect(run_rules.description).to eq('New Description')
    end
  end

  context 'when not all rule criteria are true' do
    let(:rule_criteria_plaid_category_id) { plaid_category.id + 1 }

    it 'does not update the transaction' do
      expect(run_rules.description).to eq('venmo')
    end
  end
end

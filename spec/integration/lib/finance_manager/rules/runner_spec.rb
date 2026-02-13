# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/rules/runner'

RSpec.describe FinanceManager::Rules::Runner do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:plaid_category) do
    create(
      :plaid_category,
      primary_category:  'original category',
      detailed_category: 'original category detailed'
    )
  end
  let(:other_plaid_category) { create(:plaid_category) }
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
    context 'and updating a simple scalar field' do
      it 'updates the transaction' do
        expect(run_rules.description).to eq('New Description')
      end
    end

    context 'and updating a more complex mapped field' do
      let(:new_category) { create(:plaid_category, detailed_category: 'MY NEW CATEGORY') }
      let(:rule1) do
        create(
          :transaction_rule,
          field_replacement_mappings: { plaid_category_id: new_category.id }
        )
      end
      let(:rule_criteria2) { nil }

      it 'updates the transaction' do
        expect(run_rules.plaid_category.detailed_category).to eq(new_category.detailed_category)
      end
    end
  end

  context 'when not all rule criteria are true' do
    let(:rule_criteria_plaid_category_id) { other_plaid_category.id }

    it 'does not update the transaction' do
      expect(run_rules.description).to eq('venmo')
    end
  end

  context 'when matching by account' do
    let(:rule_criteria1) do
      create(
        :rule_criteria,
        transaction_rule: rule1,
        field_name:       'account_id',
        field_qualifier:  '==',
        value_comparator: account.id
      )
    end
    let(:rule_criteria2) { nil }

    context 'and the criteria matches' do
      it 'updates the transaction' do
        expect(run_rules.description).to eq('New Description')
      end
    end
  end

  context 'when splitting a transaction' do
    let(:split_category) { create(:plaid_category, detailed_category: 'Split Category') }
    let(:split_label) { create(:label) }
    let(:rule1) do
      create(
        :transaction_rule,
        field_replacement_mappings: {}, # Explicitly set to empty hash
        split_category_id:          split_category.id,
        split_amount:               30.0,
        split_description:          'Split Part',
        split_merchant_name:        'Split Merchant',
        split_labels:               [split_label.id]
      )
    end
    let!(:rule_criteria1) do
      create(
        :rule_criteria,
        transaction_rule: rule1, # Associate with the rule1 defined in this context
        field_name:       'description',
        field_qualifier:  '==',
        value_comparator: 'venmo'
      )
    end
    let(:rule_criteria2) { nil } # No need for a second criteria for this test

    it 'creates a new split transaction and updates the original' do
      transaction # Force creation of the transaction defined in the let block
      expect { run_rules }.to change(Transaction, :count).by(1)

      transaction.reload # Reload the original transaction to get updated attributes
      split_transaction = Transaction.last

      expect(transaction.amount).to eq(60.0) # 90 - 30
      expect(transaction.split).to be(true)
      expect(transaction.transaction_group).to be_present

      expect(split_transaction.amount).to eq(30.0)
      expect(split_transaction.plaid_category).to eq(split_category)
      expect(split_transaction.description).to eq('Split Part')
      expect(split_transaction.merchant_name).to eq('Split Merchant')
      expect(split_transaction.labels.first).to eq(split_label) # Assuming only one label
      expect(split_transaction.split).to be(true)
      expect(split_transaction.transaction_group).to eq(transaction.transaction_group)
    end
  end
end

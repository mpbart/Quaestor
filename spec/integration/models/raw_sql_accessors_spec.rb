# frozen_string_literal: true

require 'rails_helper'

# Characterization coverage for the raw SQL accessors on Transaction and
# Account, which had no automated coverage before the Rails 8 upgrade. These are
# the code paths most exposed to connection-handling and adapter changes.
RSpec.describe 'Raw SQL accessors', type: :model do
  let(:user) { create(:user) }
  let(:depository) { create(:account, user: user, account_type: 'depository') }
  let(:credit) { create(:account, user: user, account_type: 'credit') }
  let(:expense_category) do
    create(
      :plaid_category,
      primary_category:  'FOOD_AND_DRINK',
      detailed_category: 'FOOD_AND_DRINK_GROCERIES'
    )
  end
  let(:income_category) do
    create(
      :plaid_category,
      primary_category:  'INCOME',
      detailed_category: 'INCOME_WAGES'
    )
  end
  let(:excluded_category) do
    create(
      :plaid_category,
      primary_category:  'TRANSFER_IN',
      detailed_category: 'TRANSFER_IN_ACCOUNT_TRANSFER'
    )
  end

  describe 'Transaction' do
    let!(:january_expense) do
      create(
        :transaction,
        user:           user,
        account:        depository,
        plaid_category: expense_category,
        amount:         -100.0,
        date:           '2023-01-10',
        merchant_name:  'Shop'
      )
    end

    before do
      create(
        :transaction,
        user:           user,
        account:        depository,
        plaid_category: expense_category,
        amount:         -50.0,
        date:           '2023-02-10',
        merchant_name:  'Other Shop'
      )
      create(
        :transaction,
        user:           user,
        account:        depository,
        plaid_category: income_category,
        amount:         1000.0,
        date:           '2023-01-20'
      )
      create(
        :transaction,
        user:           user,
        account:        depository,
        plaid_category: excluded_category,
        amount:         -999.0,
        date:           '2023-01-25'
      )
    end

    it 'totals spending per month, excluding income and excluded categories' do
      rows = Transaction.total_spending_over_time(user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([-100.0, -50.0])
    end

    it 'totals income per month' do
      rows = Transaction.total_income_over_time(user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([1000.0])
    end

    it 'totals all amounts by primary category' do
      rows = Transaction.category_totals(user.id)

      totals = rows.to_h { |row| [row['primary_category'], row['total'].to_f] }
      expect(totals).to eq(
        'FOOD_AND_DRINK' => -150.0,
        'INCOME'         => 1000.0,
        'TRANSFER_IN'    => -999.0
      )
    end

    it 'totals spending for a primary category per month' do
      rows = Transaction.primary_category_spending_over_time('FOOD_AND_DRINK', user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([-100.0, -50.0])
    end

    it 'totals spending for a detailed category per month' do
      rows = Transaction.detailed_category_spending_over_time('FOOD_AND_DRINK_GROCERIES', user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([-100.0, -50.0])
    end

    it 'totals spending for a merchant per month' do
      rows = Transaction.merchant_spending_over_time('Shop', user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([-100.0, -50.0])
    end

    it 'totals spending for a label per month' do
      label = create(:label, name: 'Groceries')
      january_expense.labels << label

      rows = Transaction.label_spending_over_time(label.id, user.id)

      expect(rows.map { |row| row['total'].to_f }).to eq([-100.0])
    end

    it 'totals spending by category per month' do
      rows = Transaction.spending_by_category_over_time(user.id)

      expect(rows.map { |row| [row['category'], row['total'].to_f] }).to eq(
        [['FOOD_AND_DRINK', -100.0], ['FOOD_AND_DRINK', -50.0]]
      )
    end
  end

  describe 'Account' do
    before do
      create(:balance, account: depository, amount: 1000.0, created_at: '2023-01-15')
      create(:balance, account: depository, amount: 1200.0, created_at: '2023-02-15')
      create(:balance, account: credit, amount: 500.0, created_at: '2023-01-15')
      create(:balance, account: credit, amount: 700.0, created_at: '2023-02-15')
    end

    it 'computes net worth from the newest balance of each account' do
      expect(Account.net_worth(user.id).to_f).to eq(500.0)
    end

    it 'computes the current balance for the given accounts' do
      expect(Account.current_balance(user.id, [depository.id]).to_f).to eq(1200.0)
    end

    it 'computes the current balance across several accounts' do
      expect(Account.current_balance(user.id, [depository.id, credit.id]).to_f).to eq(1900.0)
    end

    it 'groups balances by month for a single account' do
      rows = Account.balances_by_month(user.id, depository.id)

      expect(rows.map { |row| row['amount'].to_f }).to eq([1000.0, 1200.0])
    end

    it 'groups balances by month across all of the user accounts' do
      rows = Account.balances_by_month(user.id).to_a

      expect(rows.size).to eq(4)
      expect(rows.map { |row| row['account_id'].to_i }).to include(depository.id, credit.id)
    end
  end
end

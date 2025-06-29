# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/analytics'

RSpec.describe FinanceManager::Analytics, type: :model do
  let(:user) { create(:user) }
  let(:start_date) { '2023-01-01' }
  let(:end_date) { '2023-03-31' }
  let(:asset_account) { create(:account, user: user, account_type: 'depository') }
  let(:debt_account) { create(:account, user: user, account_type: 'credit') }
  let(:non_income_category) do
    create(:plaid_category, primary_category: 'Food and Drink', detailed_category: 'Restaurants')
  end

  describe '#compute_analytics' do
    context 'when analytic_type is net_worth_over_timeframe' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('mint_data/net_worth.json').and_return(false)

        create(:balance, account: asset_account, created_at: '2023-01-15', amount: 1000)
        create(:balance, account: debt_account, created_at: '2023-01-15', amount: 500)
        create(:balance, account: asset_account, created_at: '2023-02-15', amount: 1200)
        create(:balance, account: debt_account, created_at: '2023-02-15', amount: 600)
        create(:balance, account: asset_account, created_at: '2023-03-15', amount: 1500)
        create(:balance, account: debt_account, created_at: '2023-03-15', amount: 700)
      end

      it 'computes net worth over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'net_worth_over_timeframe',
          { user_id: user.id, start_date: start_date, end_date: end_date }
        )

        analytics.sort_by! { |h| h['sort_date'] }

        expect(analytics.length).to eq(3)

        expect(analytics[0]['month']).to eq('January 2023')
        expect(analytics[0]['assets']).to eq(1000)
        expect(analytics[0]['debts']).to eq(500)

        expect(analytics[1]['month']).to eq('February 2023')
        expect(analytics[1]['assets']).to eq(1200)
        expect(analytics[1]['debts']).to eq(600)

        expect(analytics[2]['month']).to eq('March 2023')
        expect(analytics[2]['assets']).to eq(1500)
        expect(analytics[2]['debts']).to eq(700)
      end
    end

    context 'when analytic_type is spending_over_timeframe' do
      before do
        create(:transaction, user: user, account: asset_account, amount: -100, date: '2023-01-10',
description: 'Groceries', plaid_category: non_income_category)
        create(:transaction, user: user, account: asset_account, amount: -50, date: '2023-01-20',
description: 'Coffee', plaid_category: non_income_category)
        create(:transaction, user: user, account: asset_account, amount: -200, date: '2023-02-10',
description: 'Rent', plaid_category: non_income_category)
        create(:transaction, user: user, account: asset_account, amount: -75, date: '2023-03-05',
description: 'Dinner', plaid_category: non_income_category)
      end

      it 'computes total spending over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'spending_over_timeframe',
          { user_id: user.id, start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(150)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(200)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(75)
      end
    end

    context 'when analytic_type is income_over_timeframe' do
      before do
        income_category = create(:plaid_category, primary_category:  'INCOME',
                                                  detailed_category: 'Salary')

        create(:transaction, user: user, account: asset_account, amount: 1000, date: '2023-01-10',
description: 'Paycheck', plaid_category: income_category)
        create(:transaction, user: user, account: asset_account, amount: 500, date: '2023-02-05',
description: 'Bonus', plaid_category: income_category)
        create(:transaction, user: user, account: asset_account, amount: 1200, date: '2023-03-15',
description: 'Freelance', plaid_category: income_category)
      end

      it 'computes total income over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'income_over_timeframe',
          { user_id: user.id, start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(1000)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(500)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(1200)
      end
    end

    context 'when analytic_type is spending_on_primary_category_over_timeframe' do
      let(:primary_category) do
        create(:plaid_category, primary_category: 'Food and Drink', detailed_category: 'Groceries')
      end

      before do
        create(:transaction, user: user, account: asset_account, amount: -50, date: '2023-01-05',
plaid_category: primary_category)
        create(:transaction, user: user, account: asset_account, amount: -30, date: '2023-01-10',
plaid_category: primary_category)
        create(:transaction, user: user, account: asset_account, amount: -100, date: '2023-02-01',
plaid_category: primary_category)
        create(:transaction, user: user, account: asset_account, amount: -20, date: '2023-03-15',
plaid_category: primary_category)
      end

      it 'computes spending on a primary category over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'spending_on_primary_category_over_timeframe',
          { user_id: user.id, category_name: primary_category.primary_category,
start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(80)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(100)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(20)
      end
    end

    context 'when analytic_type is spending_on_detailed_category_over_timeframe' do
      let(:detailed_category) do
        create(:plaid_category, primary_category:  'Food and Drink',
                                detailed_category: 'Restaurants')
      end

      before do
        create(:transaction, user: user, account: asset_account, amount: -25, date: '2023-01-01',
plaid_category: detailed_category)
        create(:transaction, user: user, account: asset_account, amount: -40, date: '2023-01-10',
plaid_category: detailed_category)
        create(:transaction, user: user, account: asset_account, amount: -60, date: '2023-02-01',
plaid_category: detailed_category)
        create(:transaction, user: user, account: asset_account, amount: -15, date: '2023-03-15',
plaid_category: detailed_category)
      end

      it 'computes spending on a detailed category over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'spending_on_detailed_category_over_timeframe',
          { user_id: user.id, category_name: detailed_category.detailed_category,
start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(65)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(60)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(15)
      end
    end

    context 'when analytic_type is spending_on_merchant_over_timeframe' do
      let(:merchant_name) { 'Starbucks' }

      before do
        create(:transaction, user: user, account: asset_account, amount: -5.50, date: '2023-01-01',
merchant_name: merchant_name)
        create(:transaction, user: user, account: asset_account, amount: -3.00, date: '2023-01-10',
merchant_name: merchant_name)
        create(:transaction, user: user, account: asset_account, amount: -7.25, date: '2023-02-01',
merchant_name: merchant_name)
        create(:transaction, user: user, account: asset_account, amount: -2.50, date: '2023-03-15',
merchant_name: merchant_name)
      end

      it 'computes spending on a merchant over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'spending_on_merchant_over_timeframe',
          { user_id: user.id, merchant_name: merchant_name, start_date: start_date,
end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(8.50)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(7.25)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(2.50)
      end
    end

    context 'when analytic_type is spending_on_label_over_timeframe' do
      let(:label) { create(:label, name: 'Utilities') }

      before do
        transaction1 = create(:transaction, user: user, account: asset_account, amount: -50,
date: '2023-01-01')
        transaction2 = create(:transaction, user: user, account: asset_account, amount: -75,
date: '2023-02-01')
        transaction3 = create(:transaction, user: user, account: asset_account, amount: -100,
date: '2023-03-01')

        transaction1.labels << label
        transaction2.labels << label
        transaction3.labels << label
      end

      it 'computes spending on a label over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'spending_on_label_over_timeframe',
          { user_id: user.id, label_id: label.id, start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:amount]).to eq(50)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:amount]).to eq(75)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:amount]).to eq(100)
      end
    end

    context 'when analytic_type is account_balance_history' do
      let(:account) { create(:account, user: user, account_type: 'depository') }

      before do
        create(:balance, account: account, created_at: '2023-01-15', amount: 1000)
        create(:balance, account: account, created_at: '2023-02-15', amount: 1200)
        create(:balance, account: account, created_at: '2023-03-15', amount: 1500)
      end

      it 'computes account balance history over a timeframe' do
        analytics = FinanceManager::Analytics.compute_analytics(
          'account_balance_history',
          { user_id: user.id, account_id: account.id, start_date: start_date, end_date: end_date }
        )

        expect(analytics.length).to eq(3)

        expect(analytics[0][:month]).to eq('January 2023')
        expect(analytics[0][:balance]).to eq(1000)

        expect(analytics[1][:month]).to eq('February 2023')
        expect(analytics[1][:balance]).to eq(1200)

        expect(analytics[2][:month]).to eq('March 2023')
        expect(analytics[2][:balance]).to eq(1500)
      end
    end
  end
end

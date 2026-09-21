# frozen_string_literal: true

require 'rails_helper'

# Characterization coverage for the dashboard and the income/expense JSON
# endpoint, including the humanized category helper that had to be adjusted for
# Ruby 3.4 / Rails 8.1.
RSpec.describe HomeController, type: :controller do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, account_type: 'depository') }
  let(:start_date) { 1.year.ago.to_date.to_s }
  let(:end_date) { 1.day.from_now.to_date.to_s }

  before { sign_in user }

  describe 'GET index' do
    it 'renders the dashboard' do
      get :index

      expect(response).to render_template(:index)
    end

    it 'renders the dashboard when balances exist' do
      create(:balance, account: account, amount: 1000, created_at: 1.day.ago)

      get :index

      expect(response).to render_template(:index)
    end
  end

  describe 'GET transactions_by_type' do
    # Both categories are deliberately chosen so they are not members of
    # PlaidCategory::RECURRING_CATEGORIES, which the default response filters out.
    let(:expense_category) do
      create(
        :plaid_category,
        primary_category:  'FOOD_AND_DRINK',
        detailed_category: 'FOOD_AND_DRINK_RESTAURANT'
      )
    end
    let(:income_category) do
      create(
        :plaid_category,
        primary_category:  'INCOME',
        detailed_category: 'INCOME_OTHER_INCOME'
      )
    end

    it 'renders expense rows with the humanized detailed category' do
      create(
        :transaction,
        user:           user,
        account:        account,
        plaid_category: expense_category,
        amount:         -12.0,
        date:           Date.current,
        description:    'Weekly shop'
      )

      get :transactions_by_type, params: { type: 'expense', start_date: start_date, end_date: end_date }

      payload = JSON.parse(response.body)
      expect(payload.size).to eq(1)
      expect(payload.first['description']).to eq('Weekly shop')
      expect(payload.first['amount']).to eq(-12.0)
      expect(payload.first['humanized_category']).to eq('Restaurant')
      expect(payload.first.dig('plaid_category', 'primary_category')).to eq('FOOD_AND_DRINK')
    end

    it 'renders income rows with the humanized detailed category' do
      create(
        :transaction,
        user:           user,
        account:        account,
        plaid_category: income_category,
        amount:         1000.0,
        date:           Date.current,
        description:    'Paycheck'
      )

      get :transactions_by_type, params: { type: 'income', start_date: start_date, end_date: end_date }

      payload = JSON.parse(response.body)
      expect(payload.size).to eq(1)
      expect(payload.first['humanized_category']).to eq('Other income')
    end

    it 'does not include income rows in the expense response' do
      create(
        :transaction,
        user:           user,
        account:        account,
        plaid_category: income_category,
        amount:         1000.0,
        date:           Date.current
      )

      get :transactions_by_type, params: { type: 'expense', start_date: start_date, end_date: end_date }

      expect(JSON.parse(response.body)).to eq([])
    end
  end
end

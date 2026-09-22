# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/analytics'

# Characterization coverage for the analytics JSON endpoint shape, which had no
# automated coverage before the Rails 8 upgrade.
RSpec.describe AnalyticsController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET chart_data' do
    it 'renders the analytics result as JSON' do
      allow(FinanceManager::Analytics).to receive(:compute_analytics)
        .and_return([{ 'month' => 'January 2023', 'amount' => 12.34 }])

      get :chart_data, params: {
        dataset:    'spending_over_timeframe',
        start_date: '2023-01-01',
        end_date:   '2023-03-31'
      }

      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to eq([{ 'month' => 'January 2023', 'amount' => 12.34 }])
    end

    it 'passes the current user and the permitted filters to the analytics engine' do
      allow(FinanceManager::Analytics).to receive(:compute_analytics).and_return([])

      get :chart_data, params: {
        dataset:    'spending_on_label_over_timeframe',
        label_id:   '7',
        start_date: '2023-01-01',
        end_date:   '2023-03-31'
      }

      expect(FinanceManager::Analytics).to have_received(:compute_analytics).with(
        'spending_on_label_over_timeframe',
        {
          label_id:   '7',
          user_id:    user.id,
          start_date: '2023-01-01',
          end_date:   '2023-03-31'
        }
      )
    end

    it 'renders an empty object when the analytics engine returns nothing' do
      allow(FinanceManager::Analytics).to receive(:compute_analytics).and_return(nil)

      get :chart_data, params: { dataset: 'unknown_dataset' }

      expect(JSON.parse(response.body)).to eq({})
    end
  end
end

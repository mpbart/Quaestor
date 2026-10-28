# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  let(:user)    { create(:user) }
  let(:account) { create(:account, user: user) }

  before { sign_in user }

  describe 'GET show' do
    render_views

    it 'renders the account status as Active' do
      get :show, params: { id: account.id }

      expect(response.body).to include('Status:')
      expect(response.body).to include('Active')
    end

    it 'renders the account status as Inactive and hides the mark inactive button' do
      account.update!(inactive: true)

      get :show, params: { id: account.id }

      expect(response.body).to include('Inactive')
      expect(response.body).not_to include('mark-inactive-button')
    end
  end

  describe 'POST mark_inactive' do
    it 'marks the account inactive' do
      post :mark_inactive, params: { id: account.id }

      expect(account.reload.inactive).to eq(true)
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end

    it 'does not mark another user account inactive' do
      other_account = create(:account)

      expect { post :mark_inactive, params: { id: other_account.id } }
        .not_to(change { other_account.reload.inactive })

      expect(response).to have_http_status(:not_found)
    end
  end
end

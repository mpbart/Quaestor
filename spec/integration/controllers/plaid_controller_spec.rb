# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaidController, type: :controller do
  let(:user)            { create(:user) }
  let(:plaid_client)    { double('plaid client') }
  let(:raw_client)      { double('raw plaid api client') }
  let(:public_token)    { 'public-sandbox-abcdefgh-1234-5678-9012-abcdefabcdef' }
  let(:exchange_result) { double('exchange response', item_id: 'item-id', access_token: 'access-token') }

  before do
    sign_in user
    allow(FinanceManager::PlaidClient).to receive(:new).and_return(plaid_client)
    allow(plaid_client).to receive(:client).and_return(raw_client)
    allow(plaid_client).to receive(:get_institution_information!)
    allow(raw_client).to receive(:item_public_token_exchange).and_return(exchange_result)
  end

  describe 'POST get_access_token' do
    it 'exchanges the token, creates a credential, and fetches institution information' do
      expect { post :get_access_token, params: { public_token: public_token } }
        .to change { PlaidCredential.count }.by(1)

      credential = PlaidCredential.order('created_at DESC').first
      expect(credential.user).to eq(user)
      expect(credential.plaid_item_id).to eq('item-id')
      expect(credential.access_token).to eq('access-token')
      expect(plaid_client).to have_received(:get_institution_information!).with(credential)
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end

    it 'does nothing when the public token is malformed' do
      expect { post :get_access_token, params: { public_token: 'garbage' } }
        .not_to(change { PlaidCredential.count })

      expect(response).to have_http_status(:no_content)
    end
  end
end

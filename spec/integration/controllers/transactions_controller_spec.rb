require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do 
  let(:user) { create(:user) }

  describe 'GET index' do
    before { sign_in user }

    it 'renders the page' do
      get :index

      expect(response).to render_template(:index)
    end
  end
end

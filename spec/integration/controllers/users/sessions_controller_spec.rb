# frozen_string_literal: true

require 'rails_helper'

# Characterization coverage for Devise sign-in / session behavior, which had no
# automated coverage before the Rails 8 upgrade.
RSpec.describe 'Devise session behavior', type: :request do
  let(:user) { create(:user) }

  describe 'POST /users/sign_in' do
    it 'signs in with valid credentials and grants access to a protected page' do
      post user_session_path, params: { user: { email: user.email, password: user.password } }

      expect(response).to redirect_to(root_path)

      get transactions_path
      expect(response).to have_http_status(:ok)
    end

    it 'rejects invalid credentials without creating a session' do
      post user_session_path, params: { user: { email: user.email, password: 'incorrect' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Log in')

      get transactions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects an unknown email' do
      post user_session_path, params: { user: { email: 'nobody@example.com', password: 'incorrect' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Log in')
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'ends the session so protected pages redirect again' do
      post user_session_path, params: { user: { email: user.email, password: user.password } }
      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)

      get transactions_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'unauthenticated access' do
    it 'redirects protected pages to the sign-in page' do
      get transactions_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

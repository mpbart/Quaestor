# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  render_views

  let(:attributes) { attributes_for(:user) }

  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  context 'on a fresh install' do
    it 'allows the sign-up page' do
      get :new

      expect(response).to have_http_status(:ok)
    end

    it 'creates the initial owner' do
      expect { post :create, params: { user: attributes } }.to change(User, :count).by(1)
      expect(User.last).not_to be_member
    end
  end

  context 'when a user exists' do
    let(:owner) { create(:user) }

    before { owner }

    it 'redirects the sign-up page to sign-in' do
      get :new

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects a direct sign-up POST without creating a login' do
      expect { post :create, params: { user: attributes } }.not_to(change(User, :count))
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'as an existing member' do
    let(:password) { SecureRandom.uuid }
    let(:new_password) { SecureRandom.uuid }
    let(:member) { create(:user, :member, password: password) }

    before { sign_in member }

    it 'allows the password change page' do
      get :edit

      expect(response).to have_http_status(:ok)
    end

    it 'allows changing the password without changing household ownership' do
      patch :update, params: {
        user: {
          current_password:      password,
          password:              new_password,
          password_confirmation: new_password,
          owner_id:              nil
        }
      }

      expect(member.reload.valid_password?(new_password)).to be(true)
      expect(member).to be_member
    end
  end
end

RSpec.describe Users::SessionsController, type: :controller do
  render_views

  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  it 'shows sign-up on a fresh install' do
    get :new

    expect(response.body).to include('Sign up')
  end

  context 'when a user exists' do
    let(:owner) { create(:user) }

    before { owner }

    it 'hides public sign-up and authenticated account controls' do
      get :new

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Sign up', 'link-button', 'backup-database-button')
    end
  end
end

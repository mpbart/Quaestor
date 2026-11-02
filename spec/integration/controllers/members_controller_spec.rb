# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembersController, type: :controller do
  render_views

  let(:owner) { create(:user) }

  before { sign_in owner }

  describe 'GET index' do
    let(:member) { create(:user, :member, owner: owner) }
    let(:other_member) { create(:user, :member) }

    before do
      member
      other_member
    end

    it 'lists only the current owner’s members' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member.email, 'Initial password', 'Remove login')
      expect(response.body).not_to include(other_member.email)
    end
  end

  describe 'POST create' do
    let(:attributes) { attributes_for(:user) }

    it 'creates a login attached to the current owner' do
      expect { post :create, params: { user: attributes } }.to change { owner.members.count }.by(1)

      expect(owner.members.last.valid_password?(attributes[:password])).to be(true)
      expect(response).to redirect_to(members_path)
    end

    context 'with an attempted owner override' do
      let(:other_owner) { create(:user) }

      it 'ignores the supplied owner id' do
        post :create, params: { user: attributes.merge(owner_id: other_owner.id) }

        expect(User.find_by!(email: attributes[:email]).owner).to eq(owner)
      end
    end

    context 'with invalid input' do
      let(:attributes) { attributes_for(:user, email: 'invalid', password: 'short') }

      it 'renders errors without creating a login or showing the password' do
        expect { post :create, params: { user: attributes } }.not_to(change(User, :count))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Email is invalid', 'Password is too short')
        expect(Nokogiri::HTML(response.body).at_css('input[type="password"]')['value']).to be_blank
      end
    end

    context 'with an existing email' do
      let(:attributes) { attributes_for(:user, email: owner.email) }

      it 'does not convert an existing owner into a member' do
        expect { post :create, params: { user: attributes } }.not_to(change(User, :count))
        expect(response).to have_http_status(:unprocessable_entity)
        expect(owner.reload).not_to be_member
      end
    end
  end

  describe 'DELETE destroy' do
    let(:member) { create(:user, :member, owner: owner) }
    let(:account) { create(:account, user: owner) }
    let(:transaction) { create(:transaction, user: owner, account: account) }

    before do
      member
      transaction
    end

    it 'removes only the login and preserves household financial data' do
      expect { delete :destroy, params: { id: member.id } }.to change(User, :count).by(-1)

      expect(response).to redirect_to(members_path)
      expect(owner.reload.accounts).to include(account)
      expect(owner.transactions).to include(transaction)
    end

    it 'cannot remove the owner' do
      expect { delete :destroy, params: { id: owner.id } }.to raise_error(ActiveRecord::RecordNotFound)
      expect(User.exists?(owner.id)).to be(true)
    end

    context 'with another household’s member' do
      let(:other_member) { create(:user, :member) }

      it 'cannot remove that login' do
        expect { delete :destroy, params: { id: other_member.id } }.to raise_error(ActiveRecord::RecordNotFound)
        expect(User.exists?(other_member.id)).to be(true)
      end
    end
  end

  context 'as a member' do
    let(:member) { create(:user, :member, owner: owner) }
    let(:attributes) { attributes_for(:user) }

    before { sign_in member }

    it 'cannot view member management' do
      get :index

      expect(response).to redirect_to(root_path)
    end

    it 'cannot create a login' do
      expect { post :create, params: { user: attributes }, format: :json }.not_to(change(User, :count))
      expect(response).to have_http_status(:forbidden)
    end

    it 'cannot delete a login' do
      expect { delete :destroy, params: { id: member.id }, format: :json }.not_to(change(User, :count))
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when signed out' do
    before { sign_out owner }

    it 'requires authentication' do
      get :index

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

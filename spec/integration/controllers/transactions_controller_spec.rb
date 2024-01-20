# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe TransactionsController, type: :controller do
  let(:user) { create(:user) }
  before { sign_in user }

  describe 'GET index' do
    it 'renders the page' do
      get :index

      expect(response).to render_template(:index)
    end
  end

  describe 'GET show' do
    let(:transaction) { create(:transaction, user: user) }

    context 'which exists' do
      it 'renders the page' do
        get :show, params: { id: transaction.id }

        expect(response).to render_template(:show)
      end
    end

    context 'which does not exist' do
      it 'renders an error' do
        expect { get :show, params: { id: SecureRandom.uuid } }.to raise_error
      end
    end
  end

  describe 'update transaction' do
    let(:transaction) { create(:transaction, user: user) }
    let(:new_description) { 'new description' }

    it 'returns a success response' do
      patch :update, params: { id: transaction.id, transaction: { description: new_description } }

      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end

    it 'updates the transaction' do
      patch :update, params: { id: transaction.id, transaction: { description: new_description } }

      expect(transaction.reload.description).to eq(new_description)
    end
  end

  describe 'split transaction' do
    let!(:transaction) { create(:transaction, user: user, amount: 100.0) }

    subject(:split_transaction) do
      post :split_transactions,
           params: { transaction: { amount: 40.0, parent_transaction_id: transaction.id } }
    end

    it 'returns a success response' do
      split_transaction

      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end

    it 'creates the new transaction' do
      expect { split_transaction }.to change { Transaction.count }.by(1)
    end

    it 'updates the original transaction' do
      split_transaction

      transaction.reload
      expect(transaction.amount).to eq(60.0)
      expect(transaction.split).to eq(true)
    end
  end
end

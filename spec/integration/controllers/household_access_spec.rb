# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  let(:owner) { create(:user) }
  let(:member) { create(:user, :member, owner: owner) }
  let(:account) { create(:account, user: owner) }

  before { sign_in member }

  describe 'member restrictions' do
    before do
      account
      allow(DatabaseBackupWorker).to receive(:perform_async)
    end

    it 'rejects manual account creation without creating an account or balance' do
      expect { post :create, params: { account: { name: 'Blocked', balance: '100' } }, format: :json }
        .not_to(change { [Account.count, Balance.count] })
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq('success' => false)
    end

    it 'rejects deactivation without changing the account' do
      expect { post :mark_inactive, params: { id: account.id }, format: :json }
        .not_to(change { account.reload.inactive })
      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects explicit backups without enqueuing a job' do
      post :backup, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(DatabaseBackupWorker).not_to have_received(:perform_async)
    end

    it 'returns JSON for XHR requests even without a JSON format' do
      post :backup, xhr: true

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq('success' => false)
    end

    it 'redirects HTML requests with an alert' do
      post :mark_inactive, params: { id: account.id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('household owner')
      expect(account.reload).not_to be_inactive
    end
  end

  describe 'member access' do
    it 'allows renaming the owner’s account' do
      patch :rename, params: { id: account.id, name: 'Shared account' }

      expect(response.parsed_body).to eq('success' => true)
      expect(account.reload.name).to eq('Shared account')
    end

    context 'with another household’s account' do
      let(:other_account) { create(:account) }

      it 'does not allow renaming that account' do
        expect { patch :rename, params: { id: other_account.id, name: 'Not allowed' } }
          .not_to(change { other_account.reload.name })
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with balance history' do
      before do
        allow(FinanceManager::Analytics).to receive(:account_balance_history).and_return([])
      end

      it 'queries using the owner’s id' do
        get :balance_history, params: { id: account.id }

        expect(FinanceManager::Analytics).to have_received(:account_balance_history)
          .with(hash_including(user_id: owner.id, account_id: account.id.to_s))
      end
    end

    context 'when rendering the account page' do
      render_views

      it 'hides restricted controls but keeps rename available' do
        get :show, params: { id: account.id }

        expect(response.body).not_to include('fix-account-button', 'mark-inactive-button')
        expect(response.body).to include('rename-account-button')
      end
    end
  end

  describe 'owner access' do
    before do
      sign_in owner
      allow(DatabaseBackupWorker).to receive(:perform_async)
    end

    it 'allows manual account creation' do
      expect do
        post :create, params: { account: { name: 'Manual account', type: 'depository', balance: '100' } }
      end.to change { owner.accounts.count }.by(1)
      expect(response.parsed_body).to eq('success' => true)
    end

    it 'allows explicit backups' do
      post :backup

      expect(DatabaseBackupWorker).to have_received(:perform_async).with(owner.id)
    end
  end
end

RSpec.describe PlaidController, type: :controller do
  let(:owner) { create(:user) }
  let(:member) { create(:user, :member, owner: owner) }

  before { sign_in member }

  describe 'member restrictions' do
    before do
      allow(FinanceManager::Interface).to receive(:new)
      allow(CacheManager).to receive(:get)
      allow(FinanceManager::PlaidClient).to receive(:new)
    end

    [:get_access_token, :create_link_token, :fix_account_connection].each do |action|
      it "rejects #{action} before any Plaid interaction" do
        expect { post action, params: { account_id: '1', public_token: 'invalid' }, format: :json }
          .not_to(change(PlaidCredential, :count))
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq('success' => false)
        expect(FinanceManager::Interface).not_to have_received(:new)
        expect(FinanceManager::PlaidClient).not_to have_received(:new)
        expect(CacheManager).not_to have_received(:get)
      end
    end
  end

  describe 'shared refresh' do
    let(:manager) { instance_double(FinanceManager::Interface, refresh_accounts: [], refresh_transactions: []) }

    before do
      allow(FinanceManager::Interface).to receive(:new).with(owner).and_return(manager)
      allow(DatabaseBackupWorker).to receive(:perform_async)
    end

    it 'refreshes the owner’s data and enqueues the owner’s backup' do
      post :refresh_accounts, format: :json

      expect(response).to have_http_status(:ok)
      expect(manager).to have_received(:refresh_accounts)
      expect(manager).to have_received(:refresh_transactions)
      expect(DatabaseBackupWorker).to have_received(:perform_async).with(owner.id)
    end
  end

  describe 'owner link token' do
    before do
      sign_in owner
      allow(CacheManager).to receive(:get).with(:plaid_link_token, owner.id).and_return('link-token')
    end

    it 'still allows linking an account' do
      post :create_link_token

      expect(response.parsed_body).to eq('link_token' => 'link-token')
    end
  end

  describe 'owner connection repair' do
    let(:account) { create(:account, user: owner) }
    let(:credential) { create(:plaid_credential, user: owner, institution_name: account.institution_name) }
    let(:raw_client) { double('Plaid API client', link_token_create: double(link_token: 'repair-token')) }
    let(:plaid_client) { instance_double(FinanceManager::PlaidClient, client: raw_client) }

    before do
      credential
      sign_in owner
      allow(FinanceManager::PlaidClient).to receive(:new).and_return(plaid_client)
    end

    it 'still allows repairing a connection' do
      post :fix_account_connection, params: { account_id: account.id }

      expect(response.parsed_body).to eq('link_token' => 'repair-token')
      expect(raw_client).to have_received(:link_token_create)
    end
  end
end

RSpec.describe HomeController, type: :controller do
  render_views

  let(:owner) { create(:user) }
  let(:member) { create(:user, :member, owner: owner) }
  let(:account) { create(:account, user: owner, account_type: 'depository') }
  let(:balance) { create(:balance, account: account, amount: 1000, created_at: 1.day.ago) }
  let(:credit_account) { create(:account, user: owner, account_type: 'credit') }
  let(:credit_balance) { create(:balance, account: credit_account, amount: 0, created_at: 1.day.ago) }

  before do
    balance
    credit_balance
    sign_in member
  end

  describe 'shared income data' do
    let(:category) { create(:plaid_category, primary_category: 'INCOME', detailed_category: 'INCOME_OTHER_INCOME') }
    let(:transaction) { create(:transaction, user: owner, account: account, plaid_category: category, amount: 100) }

    before { transaction }

    it 'returns the owner’s income transactions' do
      get :transactions_by_type, params: {
        type: 'income', start_date: 1.day.ago.to_date.to_s, end_date: 1.day.from_now.to_date.to_s
      }

      expect(response.parsed_body.pluck('id')).to eq([transaction.id])
    end
  end

  it 'shows the owner’s accounts and balances without owner-only controls' do
    get :index

    expect(assigns(:accounts)).to contain_exactly(account, credit_account)
    expect(assigns(:net_worth)).to eq(1000)
    expect(response.body).to include(account.name, '$1,000.00', 'refresh-button', 'Change Password')
    expect(response.body).not_to include(
      'add-account-button', 'link-button', 'backup-database-button', 'Manage Household'
    )
  end

  context 'as the owner' do
    before { sign_in owner }

    it 'keeps the owner-only controls visible' do
      get :index

      expect(response.body).to include(
        'add-account-button', 'link-button', 'backup-database-button', 'Manage Household'
      )
    end
  end
end

RSpec.describe TransactionsController, type: :controller do
  let(:owner) { create(:user) }
  let(:member) { create(:user, :member, owner: owner) }
  let(:account) { create(:account, user: owner) }
  let(:transaction) { create(:transaction, user: owner, account: account) }

  before do
    transaction
    sign_in member
  end

  describe 'shared transactions' do
    render_views

    let(:other_transaction) { create(:transaction) }

    before { other_transaction }

    it 'lists the owner’s transactions and subscribes to the owner’s stream' do
      get :index

      expect(assigns(:transactions)).to contain_exactly(transaction)
      source = Nokogiri::HTML(response.body).at_css('turbo-cable-stream-source')
      expect(Turbo::StreamsChannel.verified_stream_name(source['signed-stream-name']))
        .to eq("#{owner.to_gid_param}:transactions")
    end

    it 'hides permanent deletion but keeps editing available' do
      get :show, params: { id: transaction.id }

      expect(response.body).not_to include('Hard Delete')
      expect(response.body).to include('edit-transaction-form', 'split-transactions-form')
    end
  end

  it 'allows updating an owner’s transaction' do
    patch :update, params: { id: transaction.id, transaction: { description: 'Updated by member' } }

    expect(transaction.reload.description).to eq('Updated by member')
  end

  it 'allows splitting a transaction using the owner’s data' do
    expect do
      post :split_transactions, params: { transaction: { parent_transaction_id: transaction.id, amount: 4 } }
    end.to change { owner.transactions.count }.by(1)
    expect(transaction.reload.amount).to eq(6)
    expect(member.transactions).to be_empty
  end

  it 'rejects permanent deletion without removing the transaction' do
    expect { post :hard_delete, params: { transaction_id: transaction.id }, format: :json }
      .not_to(change { Transaction.with_deleted.count })
    expect(response).to have_http_status(:forbidden)
    expect(transaction.reload.deleted_at).to be_nil
  end

  context 'as the owner' do
    before { sign_in owner }

    it 'allows permanent deletion' do
      expect { post :hard_delete, params: { transaction_id: transaction.id } }
        .to change { Transaction.with_deleted.count }.by(-1)
    end
  end
end

RSpec.describe AnalyticsController, type: :controller do
  let(:member) { create(:user, :member) }

  before do
    sign_in member
    allow(FinanceManager::Analytics).to receive(:compute_analytics).and_return([])
  end

  it 'queries analytics for the owner rather than the member' do
    get :chart_data, params: { dataset: 'spending_over_timeframe', start_date: '2026-01-01', end_date: '2026-12-31' }

    expect(FinanceManager::Analytics).to have_received(:compute_analytics)
      .with('spending_over_timeframe', { user_id: member.owner_id, start_date: '2026-01-01', end_date: '2026-12-31' })
  end
end

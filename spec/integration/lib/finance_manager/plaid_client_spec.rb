# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/plaid_client'

RSpec.describe FinanceManager::PlaidClient do
  let(:instance)         { described_class.new }
  let(:api_client)       { double('plaid api client') }
  let(:client)           { double('plaid client') }
  let(:user)             { create(:user) }
  let(:institution_name) { 'financial institution' }
  let(:plaid_credential) do
    create(
      :plaid_credential,
      user:             user,
      institution_name: institution_name
    )
  end

  before do
    allow(Plaid::ApiClient).to receive(:new).with(anything).and_return(api_client)
    allow(Plaid::PlaidApi).to receive(:new).with(api_client).and_return(client)
  end

  describe '#sync_accounts' do
    let(:acct_id)            { SecureRandom.uuid }
    let(:acct_mask)          { '1234' }
    let(:acct_name)          { 'Test Acct' }
    let(:acct_official_name) { 'Official Acct Name' }
    let(:acct_type)          { Plaid::AccountType::DEPOSITORY }
    let(:acct_subtype)       { Plaid::AccountSubtype::CHECKING }
    let(:response)           { Plaid::AccountsGetResponse.new(accounts: accounts) }
    let(:accounts) do
      [Plaid::AccountBase.new(
        account_id:    acct_id,
        balances:      Plaid::AccountBalance.new(available: 10.0, current: 2.0, limit: nil),
        mask:          acct_mask,
        name:          acct_name,
        official_name: acct_official_name,
        type:          acct_type,
        subtype:       acct_subtype
      )]
    end

    subject(:sync_accounts) { instance.sync_accounts(plaid_credential) }

    context 'when no errors occur' do
      before { allow(client).to receive(:accounts_get).with(anything).and_return(response) }

      it 'records the raw response from plaid in the database' do
        expect { sync_accounts }.to change { PlaidResponse.count }.by(1)
        expect(PlaidResponse.order(created_at: :desc).first.response).to eq(response.to_hash)
      end

      it 'returns updated account information when no errors occur' do
        result = sync_accounts
        expect(result.accounts).to eq(accounts)
        expect(result.failed_institution_name).to eq(nil)
      end
    end

    context 'when the account needs to be refreshed' do
      let(:exc) do
        Plaid::ApiError.new(
          response_body: JSON.dump(
            { error_code: FinanceManager::PlaidClient::ITEM_LOGIN_REQUIRED }
          )
        )
      end

      before do
        allow(client).to receive(:accounts_get).with(anything).and_raise(exc)
      end

      it 'returns error information' do
        result = sync_accounts
        expect(result.failed_institution_name).to eq(institution_name)
      end
    end
  end

  describe '#sync_transactions' do
    let!(:category)               { create(:plaid_category) }
    let(:account)                 { create(:account, user: user) }
    let(:added)                   { [] }
    let(:modified)                { [] }
    let(:removed)                 { [] }
    let(:next_cursor)             { 'cursor' }
    let(:has_more)                { false }
    let(:transaction_id)          { SecureRandom.uuid }
    let(:response) do
      Plaid::TransactionsSyncResponse.new(
        added:       added,
        modified:    modified,
        removed:     removed,
        next_cursor: next_cursor,
        has_more:    has_more
      )
    end
    let(:added) do
      [
        Plaid::Transaction.new(
          account_id:                account.plaid_identifier,
          amount:                    12.34,
          transaction_id:            transaction_id,
          merchant_name:             'merchant',
          payment_channel:           'online',
          name:                      'description',
          date:                      Date.current,
          pending:                   false,
          payment_meta:              {},
          location:                  {},
          pending_transaction_id:    nil,
          account_owner:             '1234',
          personal_finance_category: Plaid::PersonalFinanceCategory.new(
            primary:          category.primary_category,
            detailed:         category.detailed_category,
            confidence_level: 'HIGH'
          )
        )
      ]
    end

    subject(:sync_transactions) { instance.sync_transactions(plaid_credential) }

    context 'when no errors occur' do
      before { allow(client).to receive(:transactions_sync).with(anything).and_return(response) }

      it 'records the raw response from plaid in the database' do
        expect { sync_transactions }.to change { PlaidResponse.count }.by(1)
      end

      it 'returns updated transaction information when no errors occur' do
        result = sync_transactions
        expect(result.added).to eq(added)
        expect(result.modified).to eq(modified)
        expect(result.removed).to eq(removed)
        expect(result.cursor).to eq(next_cursor)
        expect(result.failed_institution_name).to eq(nil)
      end
    end

    context 'when the account needs to be refreshed' do
      let(:exc) do
        Plaid::ApiError.new(
          response_body: JSON.dump(
            { error_code: FinanceManager::PlaidClient::ITEM_LOGIN_REQUIRED }
          )
        )
      end

      before { allow(client).to receive(:transactions_sync).with(anything).and_raise(exc) }

      it 'returns error information if errors do occur' do
        result = sync_transactions
        expect(result.failed_institution_name).to eq(institution_name)
      end
    end
  end

  describe '#get_institution_information' do
    let(:inst_id)       { 999 }
    let(:inst_name)     { 'new institution name' }
    let(:institution)   { Plaid::Institution.new(institution_id: inst_id, name: inst_name) }
    let(:response)      { Plaid::InstitutionsGetByIdResponse.new(institution: institution) }
    let(:item_response) do
      Plaid::ItemGetResponse.new(item: Plaid::Item.new(institution_id: inst_id))
    end

    before do
      allow(client).to receive(:item_get).and_return(item_response)
      allow(client).to receive(:institutions_get_by_id).and_return(response)
    end

    subject(:get_institution_information!) do
      instance.get_institution_information!(plaid_credential)
    end

    it "updates the plaid credential's name and id" do
      get_institution_information!

      expect(plaid_credential.reload.institution_id).to eq(inst_id.to_s)
      expect(plaid_credential.reload.institution_name).to eq(inst_name)
    end
  end
end

require 'rails_helper'
require 'finance_manager/interface'

RSpec.describe FinanceManager::Interface do
  let(:instance)          { described_class.new(user) }
  let(:plaid_client)      { double('plaid client') }
  let(:user)              { create(:user) }
  let!(:plaid_credential) { create(:plaid_credential, user: user) }

  before do
    allow_any_instance_of(described_class).to receive(:create_plaid_client).and_return(plaid_client)
  end

  describe '#refresh_accounts' do
    let(:acct_id)            { SecureRandom.uuid }
    let(:acct_mask)          { '1234' }
    let(:acct_name)          { 'Test Account' }
    let(:acct_official_name) { 'Very Official Name' }
    let(:acct_type)          { Plaid::AccountType::DEPOSITORY }
    let(:acct_subtype)       { Plaid::AccountSubtype::CHECKING }
    let(:response)           { Plaid::AccountsGetResponse.new(accounts: accounts) }
    let(:accounts) do
      [Plaid::AccountBase.new(
        account_id:    acct_id,
        balances:      Plaid::AccountBalance.new(available: 5.0, current: 10.0, limit: nil),
        mask:          acct_mask,
        name:          acct_name,
        official_name: acct_official_name,
        type:          acct_type,
        subtype:       acct_subtype)
      ]
    end

    before do
      allow(plaid_client).to receive(:accounts_get).and_return(response)
    end

    subject(:refresh_accounts) { instance.refresh_accounts }

    it 'records the raw response from plaid in the database' do
      expect{ refresh_accounts }.to change{ PlaidResponse.count }.by(1)
      expect(PlaidResponse.order('created_at DESC').first.response).to eq(response.to_hash)
    end

    context 'when the account is new' do
      it 'creates a new account' do
        expect { refresh_accounts }.to change{ Account.count }.by(1)

        saved_acct = Account.order('created_at DESC').first
        expect(saved_acct.plaid_identifier).to eq(acct_id)
        expect(saved_acct.mask).to eq(acct_mask)
        expect(saved_acct.name).to eq(acct_name)
        expect(saved_acct.official_name).to eq(acct_official_name)
        expect(saved_acct.account_type).to eq(acct_type)
        expect(saved_acct.account_sub_type).to eq(acct_subtype)
      end

      it 'creates a new balance' do
        expect{ refresh_accounts }.to change{ Balance.count }.by(1)
        balance = Balance.order('created_at DESC').first

        expect(balance.amount).to eq(10.0)
        expect(balance.available).to eq(5.0)
        expect(balance.limit).to eq(nil)
      end
    end

    context 'when the account already exists' do
      before { create(:account, plaid_identifier: acct_id, user: user) }

      it 'does not create a new account in the database' do
        expect{ refresh_accounts }.to change{ Account.count }.by(0)
      end

      it 'creates a new balance' do
        expect{ refresh_accounts }.to change{ Balance.count }.by(1)
      end
    end
  end

  describe '#refresh_transactions' do
  end

  describe '#edit_transaction!' do
  end

  describe '#split_transaction!' do
  end

  describe '#add_institution_information' do
  end
end

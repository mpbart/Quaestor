# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/interface'

RSpec.describe FinanceManager::Interface do
  let(:instance)          { described_class.new(user) }
  let(:plaid_client)      { double('plaid client') }
  let(:user)              { create(:user) }
  let!(:plaid_credential) { create(:plaid_credential, user: user) }

  before do
    allow(FinanceManager::PlaidClient).to receive(:new).and_return(plaid_client)
  end

  describe '#refresh_accounts' do
    let(:acct_id)                 { SecureRandom.uuid }
    let(:acct_mask)               { '1234' }
    let(:acct_name)               { 'Test Account' }
    let(:acct_official_name)      { 'Very Official Name' }
    let(:acct_type)               { Plaid::AccountType::DEPOSITORY }
    let(:acct_subtype)            { Plaid::AccountSubtype::CHECKING }
    let(:failed_institution_name) { nil }
    let(:response) do
      FinanceManager::PlaidClient::AccountsResponse.new(
        accounts:                accounts,
        failed_institution_name: failed_institution_name
      )
    end
    let(:accounts) do
      [Plaid::AccountBase.new(
        account_id:    acct_id,
        balances:      Plaid::AccountBalance.new(available: 5.0, current: 10.0, limit: nil),
        mask:          acct_mask,
        name:          acct_name,
        official_name: acct_official_name,
        type:          acct_type,
        subtype:       acct_subtype
      )]
    end

    before do
      allow(plaid_client).to receive(:sync_accounts).and_return(response)
    end

    subject(:refresh_accounts) { instance.refresh_accounts }

    context 'when the account is new' do
      it 'creates a new account' do
        expect { refresh_accounts }.to change { Account.count }.by(1)

        saved_acct = Account.order('created_at DESC').first
        expect(saved_acct.plaid_identifier).to eq(acct_id)
        expect(saved_acct.mask).to eq(acct_mask)
        expect(saved_acct.name).to eq(acct_name)
        expect(saved_acct.official_name).to eq(acct_official_name)
        expect(saved_acct.account_type).to eq(acct_type)
        expect(saved_acct.account_sub_type).to eq(acct_subtype)
      end

      it 'creates a new balance' do
        expect { refresh_accounts }.to change { Balance.count }.by(1)
        balance = Balance.order('created_at DESC').first

        expect(balance.amount).to eq(10.0)
        expect(balance.available).to eq(5.0)
        expect(balance.limit).to eq(nil)
      end
    end

    context 'when the account already exists' do
      before { create(:account, plaid_identifier: acct_id, user: user) }

      it 'does not create a new account in the database' do
        expect { refresh_accounts }.to change { Account.count }.by(0)
      end

      it 'creates a new balance' do
        expect { refresh_accounts }.to change { Balance.count }.by(1)
      end
    end
  end

  describe '#refresh_transactions' do
    let!(:category)               { create(:plaid_category) }
    let(:added)                   { [] }
    let(:modified)                { [] }
    let(:removed)                 { [] }
    let(:cursor)                  { 'cursor' }
    let(:has_more)                { false }
    let(:account)                 { create(:account, user: user) }
    let(:failed_institution_name) { nil }
    let(:response) do
      FinanceManager::PlaidClient::TransactionsResponse.new(
        added:                   added,
        modified:                modified,
        removed:                 removed,
        cursor:                  cursor,
        failed_institution_name: failed_institution_name
      )
    end

    before do
      allow(plaid_client).to receive(:sync_transactions).and_return(response)
    end

    subject(:refresh_transactions) { instance.refresh_transactions }

    context 'when adding a transaction' do
      let(:transaction_id) { SecureRandom.uuid }
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

      it 'creates the transaction' do
        expect { refresh_transactions }.to change { Transaction.count }.by(1)
        transaction = Transaction.order('created_at DESC').first

        expect(transaction.account).to eq(account)
        expect(transaction.user).to eq(user)
        expect(transaction.plaid_category.detailed_category).to eq(category.detailed_category)
        expect(transaction.id).to eq(transaction_id)
      end
    end

    context 'when modifying a transaction' do
      let(:existing_transaction) { create(:transaction, account: account, user: user) }
      let(:modified) do
        [
          Plaid::Transaction.new(
            account_id:                account.plaid_identifier,
            amount:                    12.34,
            transaction_id:            existing_transaction.id,
            merchant_name:             existing_transaction.merchant_name,
            payment_channel:           existing_transaction.payment_channel,
            name:                      existing_transaction.description,
            date:                      existing_transaction.date,
            pending:                   existing_transaction.pending,
            payment_meta:              existing_transaction.payment_metadata,
            location:                  existing_transaction.location_metadata,
            pending_transaction_id:    existing_transaction.pending_transaction_id,
            account_owner:             existing_transaction.account_owner,
            personal_finance_category: Plaid::PersonalFinanceCategory.new(
              primary:          existing_transaction.plaid_category.primary_category,
              detailed:         existing_transaction.plaid_category.detailed_category,
              confidence_level: existing_transaction.category_confidence
            )
          )
        ]
      end

      it 'updates the existing transaction' do
        refresh_transactions

        expect(existing_transaction.reload.amount).to eq(12.34)
      end
    end

    context 'when removing a transaction' do
      let(:existing_transaction) do
        create(:transaction, pending: true, account: account, user: user)
      end
      let(:removed) do
        [Plaid::Transaction.new(transaction_id: existing_transaction.id)]
      end

      it 'soft-deletes the transaction' do
        expect { refresh_transactions }.to change { Transaction.count }.by(-1)
        expect(Transaction.unscoped.find_by(id: existing_transaction.id).deleted_at).not_to eq(nil)
      end
    end

    context 'when an error occurs handling transaction updates' do
      let(:added) { [Plaid::Transaction.new] }

      it 'rolls back the transaction and does not save any new records' do
        expect { refresh_transactions }.to raise_error {
                                             FinanceManager::Transaction::UnknownAccountError
                                           }
          .and change { Transaction.count }.by(0)
          .and change { PlaidResponse.count }.by(0)
        expect(plaid_credential.reload.cursor).not_to eq(cursor)
      end
    end

    it 'updates the cursor' do
      refresh_transactions

      expect(plaid_credential.reload.cursor).to eq(cursor)
    end
  end

  describe '#split_transaction!' do
    let!(:existing_transaction) do
      create(:transaction, amount: original_amount, account: account, user: user)
    end
    let(:split_details)         { { amount: 3.50 } }
    let(:original_amount)       { 10.0 }
    let(:account)               { create(:account, user: user) }

    subject(:split_transaction) do
      instance.split_transaction!(existing_transaction.id, split_details)
    end

    context 'when the transaction is successfully split' do
      it 'saves the new transaction successfully' do
        expect { split_transaction }.to change { Transaction.count }.by(1)
        split_transaction = user.transactions.where.not(id: existing_transaction.id).take

        expect(split_transaction.amount).to eq(3.50)
        expect(split_transaction.split).to eq(true)
        expect(existing_transaction.reload.amount).to eq(original_amount - 3.50)
        expect(existing_transaction.split).to eq(true)
        expect(existing_transaction.transaction_group).to eq(split_transaction.transaction_group)
      end
    end

    context 'when amount is not passed in' do
      let(:split_details) { { description: 'new description' } }

      it 'does not save a new transaction' do
        expect { split_transaction }.to change { Transaction.count }.by(0)
      end

      it 'returns false' do
        expect(split_transaction).to eq(false)
      end
    end

    context 'when amount is greater than the original transaction amount' do
      let(:split_details) { { amount: 11.0 } }

      it 'does not save a new transaction' do
        expect { split_transaction }.to change { Transaction.count }.by(0)
      end

      it 'returns false' do
        expect(split_transaction).to eq(false)
      end
    end
  end
end

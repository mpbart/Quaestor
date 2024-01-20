# frozen_string_literal: true

require 'finance_manager/transaction'

RSpec.describe FinanceManager::Transaction do
  let(:transaction_hash) do
    {
      transaction_id:         transaction_id,
      account_id:             account_id,
      category:               category,
      category_id:            category_id,
      transaction_type:       transaction_type,
      description:            description,
      amount:                 amount,
      date:                   date,
      pending:                pending,
      payment_metadata:       payment_metadata,
      location_metadata:      location_metadata,
      pending_transaction_id: pending_transaction_id,
      account_owner:          account_owner
    }
  end
  let(:transaction_id)         { 1 }
  let(:account_id)             { 2 }
  let(:category)               { 'abc' }
  let(:category_id)            { '10' }
  let(:transaction_type)       { 'type' }
  let(:description)            { 'some text here' }
  let(:amount)                 { 10.5 }
  let(:date)                   { '2020-05-10' }
  let(:pending)                { true }
  let(:payment_metadata)       { {} }
  let(:location_metadata)      { {} }
  let(:pending_transaction_id) { 3 }
  let(:account_owner)          { 'owner' }
  let(:user)                   { double('user') }
  let(:account)                { double('account', user: user) }
  let(:transaction_double)     { double('transaction') }
  let(:account_double)         { double('account double') }

  before do
    stub_const('Account', account_double)
    stub_const('Transaction', transaction_double)
  end

  describe '.handle' do
    let(:previous_transaction) { nil }

    before do
      allow(account_double).to receive(:find_by).and_return(account)
      allow(transaction_double).to receive(:find_by).and_return(previous_transaction)
      allow(described_class).to receive(:create)
      allow(described_class).to receive(:update)
      allow(described_class).to receive(:update_pending)
    end

    subject(:handle) { described_class.handle(transaction_hash) }

    it 'looks up the account by id' do
      expect(account_double).to receive(:find_by).with(plaid_identifier: account_id)
      handle
    end

    context 'when the account is not found' do
      let(:account) { nil }

      it 'raises an error' do
        expect(described_class).to receive(:raise_unknown_account_error).with(transaction_hash)
        handle
      end
    end

    context 'when the transaction is an update from a previously received pending transaction' do
      let(:previous_transaction) { double('transaction') }

      it 'calls .update_pending' do
        expect(described_class).to receive(:update_pending).with(transaction_hash)
        handle
      end
    end

    context 'when the transaction has already been seen but was not previously pending' do
      let(:pending_transaction_id) { nil }
      let(:previous_transaction)   { double('transaction') }

      it 'calls .update' do
        expect(described_class).to receive(:update).with(transaction_hash, previous_transaction)
        handle
      end
    end

    context 'when the transaction is not from a previously received pending transaction' do
      let(:pending_transaction_id) { nil }

      it 'calls .create' do
        expect(described_class).to receive(:create).with(account, transaction_hash)
        handle
      end
    end
  end

  describe '.create' do
    before { allow(transaction_double).to receive(:create!) }

    subject(:create) { described_class.create(account, transaction_hash) }

    it 'creates a new transaction with the correct arguments' do
      expect(transaction_double).to receive(:create!).with(
        account:                account,
        user:                   user,
        id:                     transaction_id,
        category:               category,
        category_id:            category_id,
        transaction_type:       transaction_type,
        description:            description,
        amount:                 amount,
        date:                   date,
        pending:                pending,
        payment_metadata:       payment_metadata,
        location_metadata:      location_metadata,
        pending_transaction_id: pending_transaction_id,
        account_owner:          account_owner
      )
      create
    end
  end

  describe '.update_pending' do
    let(:previous_transaction) { double('previous transaction') }

    before do
      RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
      allow(previous_transaction).to receive(:category=).with(category)
      allow(previous_transaction).to receive(:category_id=).with(category_id)
      allow(previous_transaction).to receive(:transaction_type=).with(transaction_type)
      allow(previous_transaction).to receive(:description=).with(description)
      allow(previous_transaction).to receive(:amount=).with(amount)
      allow(previous_transaction).to receive(:date=).with(date)
      allow(previous_transaction).to receive(:pending=).with(false)
      allow(previous_transaction).to receive(:payment_metadata=).with(payment_metadata)
      allow(previous_transaction).to receive(:location_metadata=).with(location_metadata)
      allow(previous_transaction).to receive(:pending_transaction_id=).with(pending_transaction_id)
      allow(previous_transaction).to receive(:account_owner=).with(account_owner)
      allow(previous_transaction).to receive(:save!)
      allow(transaction_double).to receive(:find_by).with(id: pending_transaction_id).and_return(previous_transaction)
      allow(described_class).to receive(:update)
    end

    subject(:update_pending) { described_class.update_pending(transaction_hash) }

    it 'looks up the previous transaction by id' do
      expect(transaction_double).to receive(:find_by).with(id: pending_transaction_id)
      update_pending
    end

    context 'when the previous transaction is not found' do
      let(:previous_transaction) { nil }

      it 'calls .unfound_pending_transaction_error' do
        expect(described_class).to receive(:unfound_pending_transaction_error).with(transaction_hash)
        update_pending
      end
    end

    it 'calls .update' do
      expect(described_class).to receive(:update).with(transaction_hash, previous_transaction)
      update_pending
    end
  end
end

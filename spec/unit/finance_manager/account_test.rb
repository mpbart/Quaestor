# frozen_string_literal: true

require 'finance_manager/account'

RSpec.describe FinanceManager::Account do
  let(:user)    { double('user') }
  let(:account) { double('account') }

  describe '.handle' do
    let(:hash) do
      {
        'account_id' => account_id
      }
    end
    let(:account_id) { 1 }
    let(:credential) { double('credential', user: user) }
    let(:accounts)   { double('accounts') }

    subject(:handle) { described_class.handle(hash, credential) }

    before do
      allow(credential).to receive(:user).and_return(user)
      allow(user).to receive(:accounts).and_return(accounts)
      allow(accounts).to receive(:find_by).with(plaid_identifier: account_id).and_return(account)
      allow(described_class).to receive(:update)
      allow(described_class).to receive(:create)
    end

    it 'looks up the user' do
      expect(credential).to receive(:user)
      handle
    end

    it 'finds the correct account' do
      expect(accounts).to receive(:find_by).with(plaid_identifier: account_id)
      handle
    end

    context 'when the account exists' do
      it 'calls update' do
        expect(described_class).to receive(:update).with(account, hash)
        handle
      end
    end

    context 'when the account does not exist' do
      let(:account) { nil }

      it 'calls create' do
        expect(described_class).to receive(:create).with(hash, credential)
        handle
      end
    end
  end

  describe '.create' do
    let(:hash) do
      {
        'account_id'    => account_id,
        'name'          => name,
        'official_name' => official_name,
        'type'          => type,
        'subtype'       => sub_type,
        'mask'          => mask,
        'balances'      => balances
      }
    end
    let(:account_id)    { 1 }
    let(:name)          { 'checking account' }
    let(:official_name) { 'very offical name' }
    let(:type)          { 'checking' }
    let(:sub_type)      { '3' }
    let(:mask)          { '1234' }
    let(:balances)      { { 'key' => 'value' } }
    let(:account_double) { double('account double') }
    let(:user) { double('user') }
    let(:credential) do
      double('credential',
             user:             user,
             institution_name: 'name',
             institution_id:   1)
    end

    subject(:create) { described_class.create(hash, credential) }

    before do
      stub_const('Account', account_double)
      allow(described_class).to receive(:create_balance)
      allow(account_double).to receive(:create!).and_return(account)
    end

    it 'creates a new account with the correct arguments' do
      expect(account_double).to receive(:create!).with(
        user:             user,
        institution_name: 'name',
        institution_id:   1,
        plaid_identifier: account_id,
        name:             name,
        official_name:    official_name,
        account_type:     type,
        account_sub_type: sub_type,
        mask:             mask
      )
      create
    end

    it 'creates a new balance' do
      expect(described_class).to receive(:create_balance).with(account, balances)
      create
    end
  end

  describe '.update' do
    let(:hash) do
      {
        'name'          => name,
        'official_name' => official_name,
        'type'          => type,
        'subtype'       => sub_type,
        'mask'          => mask,
        'balances'      => balances
      }
    end
    let(:name)          { 'checking account' }
    let(:official_name) { 'very offical name' }
    let(:type)          { 'checking' }
    let(:sub_type)      { '3' }
    let(:mask)          { '1234' }
    let(:balances)      { { 'key' => 'value' } }
    let(:changed)       { false }

    subject(:update) { described_class.update(account, hash) }

    before do
      allow(account).to receive(:name=).with(name)
      allow(account).to receive(:official_name=).with(official_name)
      allow(account).to receive(:account_type=).with(type)
      allow(account).to receive(:account_sub_type=).with(sub_type)
      allow(account).to receive(:mask=).with(mask)
      allow(account).to receive(:changed?).and_return(changed)
      allow(account).to receive(:save!)
      allow(described_class).to receive(:create_balance)
    end

    context 'when the account has new details' do
      let(:changed) { true }

      it 'saves the account' do
        expect(account).to receive(:save!)
        update
      end
    end

    context 'when the account does not have new details' do
      it 'does not save the account' do
        expect(account).not_to receive(:save!)
        update
      end
    end

    it 'calls create_balance with the correct arguments' do
      expect(described_class).to receive(:create_balance).with(account, balances)
      update
    end
  end
end

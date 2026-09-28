# frozen_string_literal: true

require 'rails_helper'
require 'finance_manager/interface'

# Characterization coverage for Turbo stream rendering and broadcasting, which
# had no automated coverage before the Rails 8 upgrade.
RSpec.describe 'Turbo streams' do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let!(:plaid_credential) { create(:plaid_credential, user: user) }
  let!(:category) { create(:plaid_category) }
  let(:plaid_client) { double('plaid client') }
  let(:instance) { FinanceManager::Interface.new(user) }

  before do
    allow(FinanceManager::PlaidClient).to receive(:new).and_return(plaid_client)
  end

  describe 'rendering the transaction row partial' do
    it 'renders the row with the description and humanized category' do
      transaction = create(
        :transaction,
        user:           user,
        account:        account,
        plaid_category: category,
        description:    'A broadcast transaction',
        amount:         -12.5
      )

      html = ApplicationController.render(
        partial: 'transactions/transaction_row',
        locals:  { transaction: transaction }
      )

      expect(html).to include('A broadcast transaction')
      expect(html).to include('Pizza')
      expect(html).to include(transaction_path(transaction))
    end
  end

  describe 'broadcasting on transaction refresh' do
    let(:added) do
      [
        Plaid::Transaction.new(
          account_id:                account.plaid_identifier,
          amount:                    12.34,
          transaction_id:            SecureRandom.uuid,
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

    let(:response) do
      FinanceManager::PlaidClient::TransactionsResponse.new(
        added:                   added,
        modified:                [],
        removed:                 [],
        cursor:                  'cursor',
        failed_institution_name: nil
      )
    end

    it 'broadcasts a prepend of each new transaction to the user transactions stream' do
      allow(plaid_client).to receive(:sync_transactions).and_return(response)
      allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)

      instance.refresh_transactions

      expect(Turbo::StreamsChannel).to have_received(:broadcast_prepend_to).with(
        [user, 'transactions'],
        target:  'transactions-table-body',
        partial: 'transactions/transaction_row',
        locals:  { transaction: an_instance_of(Transaction) }
      )
    end

    it 'does not broadcast when the institution needs to be relinked' do
      failed_response = FinanceManager::PlaidClient::TransactionsResponse.new(
        added:                   [],
        modified:                [],
        removed:                 [],
        cursor:                  'cursor',
        failed_institution_name: 'Some Institution'
      )
      allow(plaid_client).to receive(:sync_transactions).and_return(failed_response)
      allow(Turbo::StreamsChannel).to receive(:broadcast_prepend_to)

      expect(instance.refresh_transactions).to eq(['Some Institution'])
      expect(Turbo::StreamsChannel).not_to have_received(:broadcast_prepend_to)
    end
  end
end

require 'finance_manager/interface'
require 'config_reader'

RSpec.describe FinanceManager::Interface do
  let(:user)                 { double('user') }
  let(:instance)             { described_class.new(user) }
  let(:plaid_response_class) { double('plaid response') }
  let(:credentials)          { [credential1, credential2] }
  let(:credential1)          { double('plaid credential 1', access_token: token) }
  let(:credential2)          { double('plaid credential 2', access_token: token) }
  let(:token)                { double('token') }

  before do
    stub_const('PlaidResponse', plaid_response_class)
    allow(user).to receive(:plaid_credentials).and_return(credentials)
  end

  describe '#plaid_client' do
    let(:config) do
      {
        'environment'=> environment,
        'client_id'=>   client_id,
        'secret'=>      secret,
      }
    end
    let(:secret)      { 'secret' }
    let(:client_id)   { 'client_id' }
    let(:environment) { {'test'=> 'sandbox'} }
    let(:client)      { double('client') }
    let(:plaid)       { class_double(Plaid::Client) }

    before do
      allow(ConfigReader).to receive(:for).and_return(config)
      allow(plaid).to receive(:new).and_return(client)
      stub_const('Plaid::Client', plaid)
      stub_const('ENV', {'RAILS_ENV' => 'test'})
    end

    subject(:plaid_client) { instance.plaid_client }

    context 'when the config does not contain a mapping for the current environment' do
      let(:environment) { {} }

      it 'raises an error' do
        expect{ plaid_client }.to raise_error{ StandardError }
      end
    end

    context 'when there is an environment mapping' do
      it 'calls .for on ConfigReader' do
        expect(ConfigReader).to receive(:for).with('plaid')
        plaid_client
      end

      it 'creates a new plaid client with the correct parameters' do
        expect(plaid).to receive(:new).with(
          env:        'sandbox',
          client_id:  client_id,
          secret:     secret,
        )
        plaid_client
      end

      it 'returns the plaid client' do
        expect(plaid_client).to eq(client)
      end
    end
  end

  describe '#refresh_accounts' do
    let(:client)          { double('client') }
    let(:accounts_double) { double('accounts') }
    let(:accounts)        { [account1, account2] }
    let(:account1)        { {'key' => 'value'} }
    let(:account2)        { {'key' => 'value2'} }
    let(:api_response)    { {accounts: accounts} }

    before do
      allow(plaid_response_class).to receive(:record_accounts_response!)
      allow(FinanceManager::Account).to receive(:handle)
      allow(client).to receive(:accounts).and_return(accounts_double)
      allow(accounts_double).to receive(:get).with(token).and_return(api_response)
      allow(instance).to receive(:plaid_client).and_return(client)
    end
    subject(:refresh_accounts) { instance.refresh_accounts }

    it 'passes the correct token to #get' do
      expect(accounts_double).to receive(:get).with(token)
      refresh_accounts
    end

    it 'calls #get for all accounts associated with the user' do
      expect(accounts_double).to receive(:get).with(token).twice
      refresh_accounts
    end

    it 'records the plaid response' do
      expect(plaid_response_class).to receive(:record_accounts_response!).twice
      refresh_accounts
    end

    context 'when no accounts are returned' do
      let(:accounts) { [] }

      it 'does not attempt to update' do
        expect(FinanceManager::Account).not_to receive(:handle)
        refresh_accounts
      end
    end

    it 'handles the response for each account' do
      expect(FinanceManager::Account).to receive(:handle).exactly(4).times
      refresh_accounts
    end
  end

  describe '#refresh_transactions' do
    let(:client)              { double('client') }
    let(:transactions_double) { double('transactions') }
    let(:start_date)          { '2020-05-01' }
    let(:end_date)            { '2020-05-05' }
    let(:api_response)        { {transactions: transactions} }
    let(:transactions)        { [transaction1, transaction2] }
    let(:transaction1)        { {'key' => 'value'} }
    let(:transaction2)        { {'key' => 'value2'} }

    before do
      allow(plaid_response_class).to receive(:record_transactions_response!)
      allow(FinanceManager::Transaction).to receive(:handle)
      allow(client).to receive(:transactions).and_return(transactions_double)
      allow(transactions_double).to receive(:get).with(token, start_date, end_date).and_return(api_response)
      allow(instance).to receive(:transactions_refresh_start_date).and_return(start_date)
      allow(instance).to receive(:transactions_refresh_end_date).and_return(end_date)
      allow(instance).to receive(:plaid_client).and_return(client)
    end
    subject(:refresh_transactions) { instance.refresh_transactions }

    it 'passes the correct arguments to #get' do
      expect(transactions_double).to receive(:get).with(token, start_date, end_date)
      refresh_transactions
    end

    it 'gets transactions for all credentials associted with the user' do
      expect(transactions_double).to receive(:get).twice
      refresh_transactions
    end

    it 'records the plaid response' do
      expect(plaid_response_class).to receive(:record_transactions_response!).twice
      refresh_transactions
    end

    context 'when there are no transactions' do
      let(:transactions) { [] }

      it 'does not attempt to update' do
        expect(FinanceManager::Transaction).not_to receive(:handle)
        refresh_transactions
      end
    end

    it 'handles each transaction in the response' do
        expect(FinanceManager::Transaction).to receive(:handle).exactly(4).times
        refresh_transactions
    end
  end
end

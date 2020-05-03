require 'plaid'
require 'config_reader'
require_relative 'account'
require_relative 'transaction'

module FinanceManager
  class Interface
    DATE_FORMAT = '%Y-%m-%d'.freeze
    
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def plaid_client
      @plaid_client ||= begin
        config = ConfigReader.for('plaid')
        env = config['environment'].fetch(ENV['RAILS_ENV']) { raise StandardError, "No mapping found for environment #{ENV['RAILS_ENV']}" }
        Plaid::Client.new(env:        env,
                          client_id:  config['client_id'],
                          secret:     config['secret'],
                          public_key: config['public_key'])
      end
    end

    def update_accounts
      user.plaid_credentials.each do |credential|
        response = plaid_client.accounts.get(credential.token)
        PlaidResponse.record_accounts_response!(response, credential)

        next unless response[:accounts]&.any?

        response[:accounts].each do |account_hash|
          FinanceManager::Account.handle(account_hash, credential)
        end
      end
    end

    def update_transactions
      user.plaid_credentials.each do |credential|
        response = plaid_client.transactions.get(credential.token,
                                                 transactions_refresh_start_date(credential),
                                                 transactions_refresh_end_date)
        PlaidResponse.record_transactions_response!(response, credential)

        next unless response[:transactions]&.any?

        response[:transactions].each do |transaction|
          FinanceManager::Transaction.handle(transaction)
        end
      end
    end

    private

    # Using a lookback window of 5 days since the last refresh so that
    # pending transactions will (hopefully) post by then
    def transactions_refresh_start_date(plaid_cred)
      (plaid_cred.user.accounts.transactions.order(:created_at).first.created_at - 5.days).strftime(DATE_FORMAT)
    end

    def transactions_refresh_end_date(plaid_cred)
      Date.today.strftime(DATE_FORMAT)
    end

  end
end

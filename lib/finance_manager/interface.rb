require 'plaid'
require 'config_reader'
require_relative 'account'

module FinanceManager
  class Interface
    
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

        return unless accounts = response[:accounts]&.any?

        accounts.each do |account_hash| 
          FinanceManager::Account.handle(account_hash, credential)
        end
      end
    end

    def update_transactions(transactions)
    end

  end
end

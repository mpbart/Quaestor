require 'plaid'
require 'config_reader'
require 'csv_import/importer'
require_relative 'account'
require_relative 'transaction'

module FinanceManager
  class Interface
    DATE_FORMAT = '%Y-%m-%d'.freeze
    
    attr_reader :user, :plaid_client

    def initialize(user)
      @user = user
      @plaid_client = create_plaid_client
    end

    # TODO: Refactor into a separate plaid object to handle all plaid-related things
    def create_plaid_client
      config = ConfigReader.for('plaid')
      # TODO: Fix this by just using ENV vars :shrug:
      #env = config['environment'].fetch(ENV['RAILS_ENV']) { raise StandardError, "No mapping found for environment #{ENV['RAILS_ENV']}" }
      plaid_config = Plaid::Configuration.new
      plaid_config.server_index = Plaid::Configuration::Environment["sandbox"]
      plaid_config.api_key["PLAID-CLIENT-ID"] = config['client_id']
      plaid_config.api_key["PLAID-SECRET"] = config['secret']

      api_client = Plaid::ApiClient.new(plaid_config)

      Plaid::PlaidApi.new(api_client)
    end

    def refresh_accounts
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          request = Plaid::AccountsGetRequest.new({ access_token: credential.access_token })
          response = plaid_client.accounts_get(request)
          accounts = response.accounts
          PlaidResponse.record_accounts_response!(response.to_hash, credential)

          next unless response.accounts&.any?

          response.accounts.each do |account|
            FinanceManager::Account.handle(account, credential)
          end
        end
      end
    end

    def refresh_transactions
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          transactions_remaining = true
          cursor = transactions_cursor(credential)
          added, modified, removed = [], [], []

          while transactions_remaining
            request = Plaid::TransactionsSyncRequest.new(
              access_token: credential.access_token,
              cursor:       cursor,
            )
            response = plaid_client.transactions_sync(request)
            PlaidResponse.record_transactions_response!(response.to_hash, credential)

            added.concat(response.added)
            modified.concat(response.modified)
            removed.concat(response.removed)

            transactions_remaining = response.has_more
            cursor = response.next_cursor
          end

          added.each { |transaction| FinanceManager::Transaction.create(transaction) }
          modified.each { |transaction| FinanceManager::Transaction.update(transaction) }
          removed.each { |transaction| FinanceManager::Transaction.remove(transaction) }
          credential.update_columns(cursor: cursor)
        end
      end
    end

    def split_transaction!(transaction_id, new_transaction_details)
      begin
        return unless transaction = ::Transaction.find(transaction_id)
        FinanceManager::Transaction.split!(
          transaction,
          new_transaction_details
        )
      rescue => e
        Rails.logger.error("Error splitting transaction: #{e}")
        false
      end
    end

    def edit_transaction!(transaction_id, new_transaction_details)
      begin
        return unless transaction = ::Transaction.find(transaction_id)
        Financemanager::Transaction.edit!(transaction, new_transaction_details)
        true
      rescue => e
        Rails.logger.error("Error editing transaction: #{e}")
        false
      end
    end

    def import_transactions_csv(csv_file)
      CsvImport::Importer.new.process_csv(csv_file)
    end

    def add_institution_information(plaid_credential)
      request = Plaid::ItemGetRequest.new({ access_token: plaid_credential.access_token })
      response = plaid_client.item_get(request)

      request = Plaid::InstitutionsGetByIdRequest.new(
        {
          institution_id: response.item.institution_id,
          country_codes: ["US"]
        }
      )
      response = plaid_client.institutions_get_by_id(request)

      plaid_credential.update_columns(
        institution_id: response.institution.institution_id,
        institution_name: response.institution.name
      )
    end

    private

    def transactions_cursor(plaid_cred)
      plaid_cred.cursor || "now"
    end

  end
end

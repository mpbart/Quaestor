# frozen_string_literal: true

require 'plaid'
require 'csv_import/importer'
require_relative 'account'
require_relative 'transaction'

module FinanceManager
  class Interface
    ITEM_LOGIN_REQUIRED = 'ITEM_LOGIN_REQUIRED'
    DATE_FORMAT = '%Y-%m-%d'

    attr_reader :user, :plaid_client

    def initialize(user)
      @user = user
      @plaid_client = create_plaid_client
    end

    # TODO: Refactor into a separate plaid object to handle all plaid-related things
    def create_plaid_client
      plaid_config = Plaid::Configuration.new
      plaid_config.server_index = Plaid::Configuration::Environment['production']
      plaid_config.api_key['PLAID-CLIENT-ID'] = ENV.fetch('PLAID_CLIENT_ID')
      plaid_config.api_key['PLAID-SECRET'] = ENV.fetch('PLAID_SECRET_ID')

      api_client = Plaid::ApiClient.new(plaid_config)

      Plaid::PlaidApi.new(api_client)
    end

    def refresh_accounts
      failed_accounts = []
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          request = Plaid::AccountsGetRequest.new({ access_token: credential.access_token })
          response = plaid_client.accounts_get(request)
          PlaidResponse.record_accounts_response!(response.to_hash, credential)

          next unless response.accounts&.any?

          response.accounts.each do |account|
            FinanceManager::Account.handle(account, credential)
          end
        rescue Plaid::ApiError => e
          body = JSON.parse(e.response_body)
          raise e unless body['error_code'] == ITEM_LOGIN_REQUIRED

          failed_accounts << credential.institution_name
          Rails.logger.error("Failed to refresh #{credential.institution_name} - #{e}")
        end
      end
      failed_accounts
    end

    def refresh_transactions
      failed_accounts = []
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          transactions_remaining = true
          cursor = transactions_cursor(credential)
          added = []
          modified = []
          removed = []

          while transactions_remaining
            request = Plaid::TransactionsSyncRequest.new(
              access_token: credential.access_token,
              cursor:       cursor
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
        rescue Plaid::ApiError => e
          body = JSON.parse(e.response_body)
          raise e unless body['error_code'] == ITEM_LOGIN_REQUIRED

          failed_accounts << credential.institution_name
          Rails.logger.error("Failed to refresh #{credential.institution_name} - #{e}")
        end
      end
      failed_accounts
    end

    def split_transaction!(transaction_id, new_transaction_details)
      return unless (transaction = ::Transaction.find(transaction_id))

      FinanceManager::Transaction.split!(
        transaction,
        new_transaction_details
      )
    rescue StandardError => e
      Rails.logger.error("Error splitting transaction: #{e}")
      false
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
          country_codes:  ['US']
        }
      )
      response = plaid_client.institutions_get_by_id(request)

      plaid_credential.update_columns(
        institution_id:   response.institution.institution_id,
        institution_name: response.institution.name
      )
    end

    private

    def transactions_cursor(plaid_cred)
      plaid_cred.cursor || 'now'
    end
  end
end

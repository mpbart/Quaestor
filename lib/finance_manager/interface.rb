# frozen_string_literal: true

require 'csv_import/importer'
require 'finance_manager/plaid_client'
require 'finance_manager/rules/runner'
require_relative 'account'
require_relative 'transaction'

module FinanceManager
  class Interface
    attr_reader :user, :plaid_client

    def initialize(user)
      @user = user
      @plaid_client = FinanceManager::PlaidClient.new
    end

    def refresh_accounts
      failed_accounts = []
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          result = plaid_client.sync_accounts(credential)

          if result.failed_institution_name.present?
            failed_accounts << result.failed_institution_name
            next
          end

          next unless result.accounts&.any?

          result.accounts.each do |account|
            FinanceManager::Account.handle(account, credential)
          end
        end
      end
      failed_accounts
    end

    def refresh_transactions
      failed_accounts = []
      user.plaid_credentials.each do |credential|
        ActiveRecord::Base.transaction do
          result = plaid_client.sync_transactions(credential)

          if result.failed_institution_name.present?
            failed_accounts << result.failed_institution_name
            next
          end

          result.added
                .map { |transaction| FinanceManager::Transaction.create(transaction) }
                .map { |transaction| FinanceManager::Rules::Runner.run_all_rules(transaction) }
                .compact
                .each(&:save!)

          result.modified
                .map { |transaction| FinanceManager::Transaction.update(transaction) }
                .map { |transaction| FinanceManager::Rules::Runner.run_all_rules(transaction) }
                .compact
                .each(&:save!)

          result.removed.each { |transaction| FinanceManager::Transaction.remove(transaction) }

          credential.update_columns(cursor: result.cursor)
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
      plaid_client.add_institution_information(plaid_credential)
    end
  end
end

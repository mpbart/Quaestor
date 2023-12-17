require 'base64'
require 'securerandom'
require 'bigdecimal'

module FinanceManager
  class Transaction
    class UnknownAccountError < StandardError; end
    class UnknownTransactionError < StandardError; end
    class BadParametersError < StandardError; end

    def self.create(transaction)
      account = ::Account.find_by(plaid_identifier: transaction.account_id)
      category = ::PlaidCategory.find_by(detailed_category: transaction.personal_finance_category.detailed)

      unknown_account_error(transaction) unless account
      unknown_category_error(transaction) unless category

      if ::Transaction.exists?(transaction.transaction_id)
        Rails.logger.warn("Duplicate transaction with ID #{transaction.transaction_id} recorded. Ignoring and continuing")
        return
      end

      ::Transaction.create!(
        account:                account,
        user:                   account.user,
        id:                     transaction.transaction_id,
        category_confidence:    transaction.personal_finance_category.confidence_level,
        plaid_category_id:      category.id,
        merchant_name:          transaction.merchant_name,
        payment_channel:        transaction.payment_channel,
        description:            transaction.name,
        amount:                 transaction.amount,
        date:                   transaction.date,
        pending:                transaction.pending,
        payment_metadata:       transaction.payment_meta,
        location_metadata:      transaction.location,
        pending_transaction_id: transaction.pending_transaction_id,
        account_owner:          transaction.account_owner,
      )
    end

    def self.update(transaction)
      existing = ::Transaction.find_by(id: transaction.transaction_id)
      Rails.logger.warn("Could not find transaction to update with id #{transaction.transaction_id}") unless existing

      category = ::PlaidCategory.find_by(detailed_category: transaction.personal_finance_category.detailed)
      unknown_category_error(transaction) unless category

      existing.id                     = transaction.transaction_id
      existing.category_confidence    = transaction.personal_finance_category.confidence_level
      existing.plaid_category_id      = category.id
      existing.merchant_name          = transaction.merchant_name
      existing.payment_channel        = transaction.payment_channel
      existing.description            = transaction.name
      existing.amount                 = transaction.amount
      existing.date                   = transaction.date
      existing.pending                = transaction.pending
      existing.payment_metadata       = transaction.payment_meta
      existing.location_metadata      = transaction.location
      existing.pending_transaction_id = transaction.pending_transaction_id
      existing.account_owner          = transaction.account_owner

      existing.save! if existing.changed?
    end

    def self.remove(transaction)
      transaction = ::Transaction.find_by(id: transaction.transaction_id)
      Rails.logger.warn("Could not find transaction to remove with id #{transaction.transaction_id}") unless transaction

      transaction.destroy
    end

    def self.split!(original_transaction, new_transaction_details)
      if new_transaction_details[:amount].nil?
        raise BadParametersError.new("Amount must be filled when splitting a transaction")
      end

      return false unless new_transaction_details[:amount].to_f > 0.0

      ActiveRecord::Base.transaction do
        new_transaction_record = ::Transaction.create!(original_transaction.attributes.except('id')
          .merge(new_transaction_details.reject{ |k,v| v.blank? })
          .merge({id: generate_transaction_id, split: true})
        )
        new_transaction_record.split = true
        new_transaction_record.save!

        original_transaction.amount -= BigDecimal(new_transaction_details[:amount].to_s)
        original_transaction.split = true
        original_transaction.save!

        add_to_transaction_group!(original_transaction, new_transaction_record)
      end

      true
    end

    def self.add_to_transaction_group!(original_transaction, new_transaction)
      if original_transaction.transaction_group.present?
        group = original_transaction.transaction_group
        group.transactions << new_transaction
      else
        group = ::TransactionGroup.create!
        group.transactions << original_transaction
        group.transactions << new_transaction
      end
    end

    def self.edit!(transaction_record, new_transaction_details)
      transaction_record.update!(**new_transaction_details)
    end

    def self.generate_transaction_id
      Base64.encode64(SecureRandom.random_bytes(36))[..-2]
    end

    def self.unknown_account_error(transaction)
      raise UnknownAccountError, "Could not find account matching #{transaction.account_id} for transaction #{transaction[:transaction_id]}"
    end

    def self.unknown_transaction_error(transaction)
      raise UnknownTransactionError, "Could not find transaction with id #{transaction.id}"
    end

    def self.unknown_category_error(transaction)
      raise UnknownCategoryError, "Could not find category for #{transaction.personal_finance_category.detailed_category}"
    end
  end
end

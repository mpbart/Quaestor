require 'base64'
require 'securerandom'
require 'bigdecimal'

module Entity
  class Transaction
    class UnknownAccountError < StandardError; end
    class UnknownTransactionError < StandardError; end
    class BadParametersError < StandardError; end

    attr_accessor :transaction

    def initialize(transaction_id)
      @transaction = Transaction.find(transaction_id)
    end

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

    def self.update(plaid_transaction)
      category = ::PlaidCategory.find_by(detailed_category: plaid_transaction.personal_finance_category.detailed)
      unknown_category_error(plaid_transaction) unless category

      transaction.id                     = plaid_transaction.transaction_id
      transaction.category_confidence    = plaid_transaction.personal_finance_category.confidence_level
      transaction.plaid_category_id      = category.id
      transaction.merchant_name          = plaid_transaction.merchant_name
      transaction.payment_channel        = plaid_transaction.payment_channel
      transaction.description            = plaid_transaction.name
      transaction.amount                 = plaid_transaction.amount
      transaction.date                   = plaid_transaction.date
      transaction.pending                = plaid_transaction.pending
      transaction.payment_metadata       = plaid_transaction.payment_meta
      transaction.location_metadata      = plaid_transaction.location
      transaction.pending_transaction_id = plaid_transaction.pending_transaction_id
      transaction.account_owner          = plaid_transaction.account_owner

      existing.save! if transaction.changed?
    end

    def self.remove
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

    def delete!
      transaction.destroy_fully!
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

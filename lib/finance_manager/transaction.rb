module FinanceManager
  class Transaction
    class UnknownAccountError < StandardError; end
    class UnknownTransactionError < StandardError; end
    class BadParametersError < StandardError; end

    def self.create(transaction)
      account = ::Account.find_by(plaid_identifier: transaction.account_id)
      raise_unknown_account_error(transaction) unless account

      ::Transaction.create!(
        account:                account,
        user:                   account.user,
        id:                     transaction.transaction_id,
        primary_category:       transaction.personal_finance_category.primary,
        detailed_category:      transaction.personal_finance_category.detailed,
        category_confidence:    transaction.personal_finance_category.confidence_level,
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
      pending = ::Transaction.find_by(id: transaction.pending_transaction_id)
      create(transaction) unless pending

      pending.id                     = transaction.id
      pending.primary_category       = transaction.primary_category
      pending.detailed_category      = transaction.detailed_category
      pending.category_confidence    = transaction.category_confidence
      pending.merchant_name          = transaction.merchant_name
      pending.payment_channel        = transaction.payment_channel
      pending.description            = transaction.name
      pending.amount                 = transaction.amount
      pending.date                   = transaction.date
      pending.pending                = transaction.pending
      pending.payment_metadata       = transaction.payment_meta
      pending.location_metadata      = transaction.location
      pending.pending_transaction_id = transaction.pending_transaction_id
      pending.account_owner          = transaction.account_owner

      pending.save! if pending.changed?
    end

    def self.remove(transaction)
      transaction = ::Transaction.find_by(id: transaction.id)
      Rails.logger.warn("Could not find transaction to remove with id #{transaction.id}") unless transaction

      transaction.destroy
    end

    def self.split!(original_transaction, new_transaction_details)
      if new_transaction_details[:amount].nil?
        raise BadParametersError.new("Amount must be filled when splitting a transaction")
      end

      return false unless new_transaction_details[:amount].to_f > 0.0

      ActiveRecord::Base.transaction do
        t                = original_transaction.dup
        t.amount         = new_transaction_details[:amount].to_f
        t.category       = new_transaction_details[:category] || t.category
        t.category_id    = new_transaction_details[:category_id] || t.category_id
        t.split          = true
        t.save!

        original_transaction.amount -= new_transaction_details[:amount].to_f
        original_transaction.split = true
        original_transaction.save!

        add_to_transaction_group!(original_transaction, t)
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

    def self.unknown_account_error(transaction)
      raise UnknownAccountError, "Could not find account matching #{transaction.account_id} for transaction #{transaction[:transaction_id]}"
    end

    def self.unknown_transaction_error(transaction)
      raise UnknownTransactionError, "Could not find transaction with id #{transaction.id}"
    end

  end
end

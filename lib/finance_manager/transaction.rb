module FinanceManager
  class Transaction
    class UnknownAccountError < StandardError; end
    class UnfoundPendingTransactionError < StandardError; end

    def self.handle(transaction)
      account = ::Account.find_by(plaid_identifier: transaction[:account_id])
      raise_unknown_account_error(transaction) unless account

      if transaction[:pending_transaction_id]
        update_pending(transaction)
      # Use find_by here so that ActiveRecord does not raise if no record is found
      elsif record = ::Transaction.find_by(id: transaction[:transaction_id])
        update(transaction, record)
      else
        create(account, transaction)
      end
    end

    def self.create(account, transaction)
      ::Transaction.create!(
        account:                account,
        user:                   account.user,
        id:                     transaction[:transaction_id],
        category:               transaction[:category],
        category_id:            transaction[:category_id],
        transaction_type:       transaction[:transaction_type],
        description:            transaction[:description],
        amount:                 transaction[:amount],
        date:                   transaction[:date],
        pending:                transaction[:pending],
        payment_metadata:       transaction[:payment_metadata],
        location_metadata:      transaction[:location_metadata],
        pending_transaction_id: transaction[:pending_transaction_id],
        account_owner:          transaction[:account_owner],
      )
    end

    def self.update_pending(transaction)
      pending = ::Transaction.find_by(id: transaction[:pending_transaction_id])
      unfound_pending_transaction_error(transaction) unless pending

      update(transaction, pending)
    end

    def self.update(transaction_hash, record)
      record.category               = transaction_hash[:category]
      record.category_id            = transaction_hash[:category_id]
      record.transaction_type       = transaction_hash[:transaction_type]
      record.description            = transaction_hash[:description]
      record.amount                 = transaction_hash[:amount]
      record.date                   = transaction_hash[:date]
      record.pending                = false
      record.payment_metadata       = transaction_hash[:payment_metadata]
      record.location_metadata      = transaction_hash[:location_metadata]
      record.pending_transaction_id = transaction_hash[:pending_transaction_id]
      record.account_owner          = transaction_hash[:account_owner]
      record.save! if record.changed?
    end

    def self.unknown_account_error(transaction)
      raise UnknownAccountError, "Could not find account matching #{transaction[:account_id]} for transaction #{transaction[:transaction_id]}"
    end

    def self.unfound_pending_transaction_error(transaction)
      raise UnfoundPendingTransactionError, "Could not find pending transaction with id #{transaction[:pending_transaction_id]}"
    end

  end
end

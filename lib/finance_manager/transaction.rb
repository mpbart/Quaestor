module FinanceManager
  class Transaction
    class UnknownAccountError < StandardError; end

    def self.handle(transaction)
      account = Account.find_by(plaid_identifier: transaction[:account_id])
      raise_unknown_account_error(transaction) unless account

      if transaction[:pending_transaction_id]
        update(transaction)
      else
        create(account, transaction)
      end
    end

    def self.create(account, transaction)
      Transaction.create!(
        account:                account,
        id:                     transaction[:transaction_id],
        category:               transaction[:category],
        category_id:            transaction[:category_id],
        transaction_type:       transaction[:transaction_type],
        description:            transaction[:description],
        amount:                 transaction[:amount],
        date:                   transaction[:date], # TODO: Formatting?
        pending:                transaction[:pending],
        payment_metadata:       transaction[:payment_metadata],
        location_metadata:      transaction[:location_metadata],
        pending_transaction_id: transaction[:pending_transaction_id],
        account_owner:          transaction[:account_owner],
      )
    end

    def self.update(transaction)
      pending = Transaction.find(transaction[:pending_transaction_id])
      unfound_pending_transaction_error(transaction) unless pending

      pending.category               = transaction[:category]
      pending.category_id            = transaction[:category_id]
      pending.transaction_type       = transaction[:transaction_type]
      pending.description            = transaction[:description]
      pending.amount                 = transaction[:amount]
      pending.date                   = transaction[:date] # TODO: Formatting?
      pending.pending                = false
      pending.payment_metadata       = transaction[:payment_metadata]
      pending.location_metadata      = transaction[:location_metadata]
      pending.pending_transaction_id = transaction[:pending_transaction_id]
      pending.account_owner          = transaction[:account_owner]
      pending.save!
    end

    def self.unknown_account_error(transaction)
      raise UnknownAccountError, "Could not find account matching #{transaction[:account_id]} for transaction #{transaction[:transaction_id]}"
    end

    def self.unfound_pending_transaction_error(transaction)
      raise UnfoundPendingTransactionError, "Could not find pending transaction with id #{transaction[:pending_transaction_id]}"
    end

  end
end

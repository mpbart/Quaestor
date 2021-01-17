class TransactionGroup < ApplicationRecord
  has_many :transactions, foreign_key: :transaction_group_uuid, primary_key: :uuid
end

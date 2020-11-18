class SplitTransaction < ApplicationRecord
  belongs_to :parent_transaction, class_name: 'Transaction', primary_key: :id, foreign_key: :transaction_id

  scope :by_date, -> { order('date DESC') }

  def self.initialize_from_original_transaction(transaction)
    split = new
    split.transaction_id = transaction.id
    split.date           = transaction.date
    split.description    = transaction.description
    split.category       = transaction.category
    split.category_id    = transaction.category_id
    split
  end
end

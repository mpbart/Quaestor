class Transaction < ApplicationRecord
  acts_as_paranoid

  belongs_to :account
  belongs_to :user
  belongs_to :transaction_group, primary_key: :uuid, foreign_key: :transaction_group_uuid, optional: true
  belongs_to :plaid_category
  has_and_belongs_to_many :labels

  scope :by_date, -> { order('date DESC') }

  def grouped_transactions
    transaction_group&.transactions&.where&.not(id: self.id) || []
  end
end

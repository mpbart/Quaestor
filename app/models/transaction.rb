class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :transaction_group, primary_key: :uuid, foreign_key: :transaction_group_uuid, optional: true

  before_update :normalize_category

  scope :by_date, -> { order('date DESC') }

  def grouped_transactions
    transaction_group&.transactions&.where&.not(id: self.id) || []
  end

  private

  def normalize_category
    self.category = PlaidCategory.find_by(category_id: category_id).hierarchy
  end
end

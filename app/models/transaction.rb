# frozen_string_literal: true

class Transaction < ApplicationRecord
  acts_as_paranoid

  belongs_to :account, optional: true
  belongs_to :user
  belongs_to :transaction_group, primary_key: :uuid, foreign_key: :transaction_group_uuid,
optional: true
  belongs_to :plaid_category
  has_and_belongs_to_many :labels

  scope :by_date, -> { order('date DESC').order('description DESC') }

  def grouped_transactions
    transaction_group&.transactions&.where&.not(id: id) || []
  end

  def self.search_by_label_name(user, label_name, page_num)
    joins(:labels).where(
      labels: { name: label_name }
    ).where(user_id: user.id)
                  .by_date
                  .paginate(page: page_num, per_page: 50)
                  .includes(:account, :plaid_category)
  end
end

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :user

  scope :by_date, -> { order('date DESC') }
end

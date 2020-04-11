class Account < ActiveRecord::Base
  belongs_to :user
  has_many :balances
  has_many :transactions
end

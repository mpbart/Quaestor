class Label < ActiveRecord::Base
  has_and_belongs_to_many :user_transactions, class_name: 'Transaction', foreign_key: :label_id
end

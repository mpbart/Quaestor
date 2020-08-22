class SplitTransaction < ApplicationRecord
  belongs_to :parent_transaction, class_name: 'Transaction'
end

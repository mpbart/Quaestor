require 'attr_encrypted'

class PlaidResponse < ApplicationRecord
  belongs_to :plaid_credential

  attr_encrypted :response, key: ENV['ENCRYPTION_KEY'], marshal: true
end

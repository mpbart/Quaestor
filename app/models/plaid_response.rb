require 'attr_encrypted'

class PlaidResponse < ApplicationRecord
  belongs_to :plaid_credential

  attr_encrypted :response, key: ENV['ENCRYPTION_KEY'], marshal: true

  def self.record_accounts_response!(response, credential)
    PlaidResponse.create!(
      endpoint:         '/accounts/get',
      response:         response,
      plaid_credential: credential,
    )
  end
end

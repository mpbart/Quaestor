# frozen_string_literal: true

require 'plaid'
require 'attr_encrypted'

class PlaidResponse < ApplicationRecord
  belongs_to :plaid_credential

  attr_encrypted :response, key: ENV.fetch('ENCRYPTION_KEY', nil), marshal: true

  def self.record_accounts_response!(response, credential)
    PlaidResponse.create!(
      endpoint:         '/accounts/get',
      response:         response,
      plaid_credential: credential
    )
  end

  def self.record_transactions_response!(response, credential)
    PlaidResponse.create!(
      endpoint:         '/transactions/get',
      response:         response,
      plaid_credential: credential
    )
  end
end

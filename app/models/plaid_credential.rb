# frozen_string_literal: true

require 'attr_encrypted'

class PlaidCredential < ActiveRecord::Base
  belongs_to :user
  has_many :plaid_responses

  attr_encrypted :access_token, key: ENV.fetch('ENCRYPTION_KEY', nil)
end

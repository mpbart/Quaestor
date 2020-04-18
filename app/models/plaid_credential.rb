require 'attr_encrypted'

class PlaidCredential < ActiveRecord::Base
  belongs_to :user
  attr_encrypted :access_token, key: ENV['ENCRYPTION_KEY']
end

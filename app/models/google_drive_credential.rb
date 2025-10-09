# frozen_string_literal: true

require 'attr_encrypted'

class GoogleDriveCredential < ActiveRecord::Base
  belongs_to :user

  attr_encrypted :refresh_token, key: ENV.fetch('ENCRYPTION_KEY', nil)
  attr_encrypted :key_hash,
                 key:       ENV.fetch('ENCRYPTION_KEY', nil),
                 marshal:   true,
                 marshaler: JSON
end

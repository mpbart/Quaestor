# frozen_string_literal: true

module Cache
  module PlaidLinkToken
    TOKEN_TTL = 3.5 * 60 * 60

    def self.get(user_id)
      Rails.logger.info("Retrieving plaid token from cache for user_id #{user_id}")
      REDIS.get(key(user_id))
    end

    def self.set(user_id, value, exp: TOKEN_TTL)
      Rails.logger.info("Caching plaid token for user_id #{user_id} with expiration #{exp}")
      REDIS.setex(key(user_id), exp, value)
    end

    def self.exists?(user_id)
      REDIS.exists(key(user_id)) == 1
    end

    def self.clear(user_id)
      REDIS.del(key(user_id))
    end

    def self.get_value(user_id)
      client = FinanceManager::PlaidClient.new
      client.create_link_token(user_id).link_token
    end

    def self.key(user_id)
      "#{user_id}:plaid_link_token"
    end
  end
end

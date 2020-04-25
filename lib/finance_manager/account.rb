module FinanceManager
  class Account
    
    def self.handle(account_hash, credential)
      user = credential.user
      account = user.accounts.find_by(plaid_identifier: account_hash['account_id'])
      if account
        update(account, account_hash)
      else
        create(account_hash, credential.user)
      end
    end

    # TODO
    def self.update(account, account_hash)
    end

    def self.create(account_hash, user)
      account = Account.create!(
        user:             user,
        plaid_identifier: account_hash['account_id'],
        name:             account_hash['name'],
        official_name:    account_hash['official_name'],
        account_type:     account_hash['type'],
        account_sub_type: account_hash['subtype'],
        mask:             account_hash['mask'],
      )

      balance = account_hash['balances']
      Balance.create!(
        account:   account,
        amount:    balance['current'],
        available: balance['available'],
        limit:     balance['limit'],
      )
    end

  end
end

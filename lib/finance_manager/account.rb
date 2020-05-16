module FinanceManager
  class Account
    
    def self.handle(account_hash, credential)
      user = credential.user
      account = user.accounts.find_by(plaid_identifier: account_hash['account_id'])
      if account
        update(account, account_hash)
      else
        create(account_hash, credential)
      end
    end

    def self.update(account, account_hash)
      account.name             = account_hash['name']
      account.official_name    = account_hash['official_name']
      account.account_type     = account_hash['type']
      account.account_sub_type = account_hash['subtype']
      account.mask             = account_hash['mask']

      account.save! if account.changed?

      create_balance(account, account_hash['balances'])
    end

    def self.create(account_hash, credential)
      account = ::Account.create!(
        user:             credential.user,
        institution_name: credential.institution_name,
        plaid_identifier: account_hash['account_id'],
        name:             account_hash['name'],
        official_name:    account_hash['official_name'],
        account_type:     account_hash['type'],
        account_sub_type: account_hash['subtype'],
        mask:             account_hash['mask'],
      )

      create_balance(account, account_hash['balances'])
    end

    def self.create_balance(account, balance)
      Balance.create!(
        account:   account,
        amount:    balance['current'],
        available: balance['available'],
        limit:     balance['limit'],
      )
    end
    private_class_method :create_balance

  end
end

module FinanceManager
  class Account
    
    def self.handle(account, credential)
      user = credential.user
      record = user.accounts.find_by(plaid_identifier: account.account_id)
      if record
        update(record, account)
      else
        create(account, credential)
      end
    end

    def self.update(record, account)
      record.name             = account.name
      record.official_name    = account.official_name
      record.account_type     = account.type
      record.account_sub_type = account.subtype
      record.mask             = account.mask

      record.save! if record.changed?

      create_balance(record, account.balances)
    end

    def self.create(account, credential)
      record = ::Account.create!(
        user:             credential.user,
        institution_name: credential.institution_name,
        institution_id:   credential.institution_id,
        plaid_identifier: account.account_id,
        name:             account.name,
        official_name:    account.official_name,
        account_type:     account.type,
        account_sub_type: account.subtype,
        mask:             account.mask,
      )

      create_balance(record, account.balances)
    end

    def self.create_balance(account, balance)
      Balance.create!(
        account:   account,
        amount:    balance.current,
        available: balance.available,
        limit:     balance.limit,
      )
    end
    private_class_method :create_balance

  end
end

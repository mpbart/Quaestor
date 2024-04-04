# frozen_string_literal: true

module FinanceManager
  class Account
    BalanceStruct = Struct.new(:current, :available, :limit)

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
      record.official_name    = account.official_name
      record.account_type     = account.type
      record.account_sub_type = account.subtype
      record.mask             = account.mask

      record.save! if record.changed?

      # NB: account.balances is a single balance NOT an array of balances
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
        mask:             account.mask
      )

      create_balance(record, account.balances)
    end

    def self.create_manually(params, user)
      record = ::Account.create!(
        user:             user,
        institution_name: params[:institution_name],
        institution_id:   params[:institution_id],
        plaid_identifier: params[:account_id],
        name:             params[:name],
        official_name:    params[:official_name],
        account_type:     params[:type],
        account_sub_type: params[:sub_type],
        mask:             params[:mask]
      )

      Balance.create!(
        account: record,
        amount:  params[:balance]
      )
    end

    def self.create_balance(account, balance)
      # De-dupe balances so that multiple refreshes per day does not result in duplicate balance
      # records being created
      newest_balance = account.balances.order(created_at: :desc).first
      if newest_balance&.created_at&.to_date == Date.today &&
         balance.current == newest_balance.amount
        return
      end

      Balance.create!(
        account:   account,
        amount:    balance.current,
        available: balance.available,
        limit:     balance.limit
      )
    end
  end
end

module Entity
  class Balance
    def self.create(balance, account)
      ::Balance.create!(
        account:   account,
        amount:    balance.current,
        available: balance.available,
        limit:     balance.limit,
      )
    end
  end
end

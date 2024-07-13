module FinanceManager
  class Analytics
    # Return JSON array of both debts and assets over the
    # given timeframe in months.
    # TODO: currently hardcoded to 1 year
    # TODO: overlay the Mint data with this to get a full 
    # snapshot of net worth going back to the beginning
    def self.net_worth_over_timeframe(timeframe, user_id)
      Account.balances_by_month(user_id)
        .group_by{ |row| row['month'] }
        .map{ |k, v| [k, amounts_by_account_type(v)] }
        .to_h
    end

    def self.amounts_by_account_type(rows)
      rows.reduce({'assets' => 0, 'debts' => 0}) do |acc, row|
        if Account::DEBT_ACCOUNT_TYPES.include?(row['account_type'])
          acc['debts'] += row['amount']
        else
          acc['assets'] += row['amount']
        end
        acc
      end
    end

    # Return JSON array of amounts spent on the category_name within
    # the passed in timeframe in months
    # TODO: currently hardcoded to 1 year
    def self.spending_on_category_over_timeframe(category_name, timeframe)
    end

    # Return JSON array of amounts spent on the merchant_name within
    # the passed in timeframe in months
    # TODO: currently hardcoded to 1 year
    def self.spending_on_merchant_over_timeframe(merchant_name, timeframe)
    end

    # Return JSON array tallying the amounts spent on each category
    # within the given timeframe in months
    # TODO: currently hardcoded to 1 year
    def self.total_spending_on_all_categories_over_timeframe(timeframe)
    end

    # Return JSON array of spending amounts over the given timeframe
    # in months
    # TODO: currently hardcoded to 1 year
    def self.spending_over_timeframe(timeframe)
    end

    # Return JSON array of income amounts over the given timeframe in months
    # TODO: currently hardcoded to 1 year
    def self.income_over_timeframe(timeframe)
    end
  end
end

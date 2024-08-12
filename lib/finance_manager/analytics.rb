# frozen_string_literal: true

module FinanceManager
  class Analytics
    MINT_DEBT_TYPE = 'DEBT'
    # Return JSON array of both debts and assets over the
    # given timeframe in months.
    # TODO: currently hardcoded to 1 year
    def self.net_worth_over_timeframe(_timeframe, user_id)
      ::Account.balances_by_month(user_id)
               .group_by { |row| row['month'] }
               .map do |k, v|
        {
          'month'     => k.strftime('%B %Y'),
          'sort_date' => k
        }.merge(
          amounts_by_account_type(
            v,
            proc { |row| ::Account::DEBT_ACCOUNT_TYPES.include?(row['account_type']) }
          )
        )
      end
        # Remove months where both debts and assets are 0 so that we do not have duplicate months
        # where one of them has all 0s
        .reject { |row| row['assets'] == 0.0 && row['debts'] == 0.0 }
               .concat(mint_data('mint_data/net_worth.json'))
               .sort_by { |h| h['sort_date'] }
               .last(12)
    end

    def self.amounts_by_account_type(rows, is_debit_lambda)
      rows.each_with_object({ 'assets' => 0, 'debts' => 0 }) do |row, acc|
        if is_debit_lambda.call(row)
          acc['debts'] += row['amount']
        else
          acc['assets'] += row['amount']
        end
      end
    end

    def self.mint_data(filename)
      return [] unless File.exist?(filename)

      raw = File.read(filename)
      parsed = JSON.parse(raw)
      parsed['net_worth'].group_by { |row| row['date'] }
                         .map do |k, v|
        date_obj = Date.strptime(k, '%Y-%m-%d')
        {
          'month'     => date_obj.strftime('%B %Y'),
          'sort_date' => date_obj
        }.merge(
          amounts_by_account_type(
            v,
            proc { |row| row['type'] == MINT_DEBT_TYPE }
          )
        )
      end
    end

    # Return JSON array of amounts spent by month on the category_name
    # within the passed in timeframe
    # TODO: currently hardcoded to 1 year
    def self.spending_on_primary_category_over_timeframe(category_name, _timeframe, user_id)
      ::Transaction.primary_category_spending_over_time(category_name, user_id)
    end

    # Return JSON array of amounts spent by month on the category_name
    # within the passed in timeframe
    # TODO: currently hardcoded to 1 year
    def self.spending_on_detailed_category_over_timeframe(category_name, _timeframe, user_id)
      ::Transaction.detailed_category_spending_over_time(category_name, user_id).map do |spending|
        { total: spending['total'], month: spending['month'].strftime('%B %Y') }
      end
    end

    # Return JSON array of amounts spent by month on the merchant_name within
    # the passed in timeframe
    # TODO: currently hardcoded to 1 year
    def self.spending_on_merchant_over_timeframe(merchant_name, _timeframe, user_id)
      ::Transaction.merchant_spending_over_time(merchant_name, user_id).map do |spending|
        { total: spending['total'], month: spending['month'].strftime('%B %Y') }
      end
    end

    # Return JSON array tallying the total amounts spent on each category
    # within the given timeframe
    # TODO: currently hardcoded to 1 year
    def self.total_spending_on_all_categories_over_timeframe(_timeframe, user_id)
      ::Transaction.category_totals(user_id)
    end

    # Return JSON array of spending amounts over the given timeframe
    # in months
    # TODO: currently hardcoded to 1 year
    def self.spending_over_timeframe(_timeframe, user_id)
      ::Transaction.total_spending_over_time(user_id).map do |spending|
        { total: spending['total'], month: spending['month'].strftime('%B %Y') }
      end
    end

    # Return JSON array of income amounts over the given timeframe in months
    # TODO: currently hardcoded to 1 year
    def self.income_over_timeframe(_timeframe, user_id)
      ::Transaction.total_income_over_time(user_id).map do |income|
        { total: income['total'].abs, month: income['month'].strftime('%B %Y') }
      end
    end
  end
end

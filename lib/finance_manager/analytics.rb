# frozen_string_literal: true

module FinanceManager
  class Analytics
    MINT_DEBT_TYPE = 'DEBT'
    # Return JSON array of both debts and assets over the
    # given timeframe in months.
    # TODO: currently hardcoded to 1 year
    def self.net_worth_over_timeframe(user_id:, timeframe: nil)
      time_range = range_from_timeframe(timeframe)
      ::Account.balances_by_month(user_id)
               .group_by { |row| row['month'] }
               .map do |k, v|
        {
          'month'     => k.strftime('%B %Y'),
          'sort_date' => k.to_date
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
               .filter { |h| time_range.cover?(h['sort_date']) }
    end

    def self.amounts_by_account_type(rows, is_debit_lambda)
      rows.each_with_object({ 'assets' => 0, 'debts' => 0 }) do |row, acc|
        if is_debit_lambda.call(row)
          acc['debts'] += row['amount']
        else
          acc['assets'] += row['amount']
        end
      end.tap do |row|
        row['debts'] = row['debts'].round(2)
        row['assets'] = row['assets'].round(2)
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

    def self.spending_on_primary_category_over_timeframe(category_name:, user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.primary_category_spending_over_time(category_name, user_id)
        )
      )
    end

    def self.spending_on_detailed_category_over_timeframe(category_name:, user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.detailed_category_spending_over_time(category_name, user_id)
        )
      )
    end

    def self.spending_on_merchant_over_timeframe(merchant_name:, user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.merchant_spending_over_time(merchant_name, user_id)
        )
      )
    end

    def self.total_spending_on_all_categories_over_timeframe(user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.category_totals(user_id)
        )
      )
    end

    def self.spending_over_timeframe(user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.total_spending_over_time(user_id)
        )
      )
    end

    def self.income_over_timeframe(user_id:, timeframe: nil)
      present_as_hash(
        filter_for_timeframe(
          timeframe,
          ::Transaction.total_income_over_time(user_id)
        )
      )
    end

    def self.present_as_hash(records)
      records.map do |rec|
        { amount: rec['total'].abs.round(2), month: rec['month'].strftime('%B %Y') }
      end
    end

    def self.filter_for_timeframe(timeframe, records)
      time_range = range_from_timeframe(timeframe)
      records.filter { |record| time_range.cover?(record['month']) }
    end

    def self.range_from_timeframe(timeframe)
      case timeframe
      when 'last_12_months'
        (12.months.ago..Date.current)
      when 'year_to_date'
        (Date.new(Date.current.year, 1, 1)..Date.current)
      when 'all_time'
        (Date.new(1900, 1, 1)..Date.current)
      else
        raise StandardError, "Unknown timeframe for analytics query: #{timeframe}"
      end
    end
  end
end
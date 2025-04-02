# frozen_string_literal: true

module FinanceManager
  class Analytics
    class InvalidAnalyticTypeError < StandardError; end
    MINT_DEBT_TYPE = 'DEBT'

    def self.compute_analytics(analytic_type, params)
      case analytic_type
      when 'net_worth_over_timeframe'
        net_worth_over_timeframe(**params)
      when 'spending_on_primary_category_over_timeframe'
        spending_on_primary_category_over_timeframe(**params)
      when 'spending_on_detailed_category_over_timeframe'
        spending_on_detailed_category_over_timeframe(**params)
      when 'spending_on_merchant_over_timeframe'
        spending_on_merchant_over_timeframe(**params)
      when 'spending_on_label_over_timeframe'
        spending_on_label_over_timeframe(**params)
      when 'spending_over_timeframe'
        spending_over_timeframe(**params)
      when 'income_over_timeframe'
        income_over_timeframe(**params)
      when 'total_spending_on_all_categories_over_timeframe'
        total_spending_on_all_categories_over_timeframe(**params)
      else
        raise InvalidAnalyticTypeError, "Analytic type #{analytic_type} not allowed"
      end
    end

    # Return JSON array of both debts and assets over the
    # given timeframe in months.
    def self.net_worth_over_timeframe(user_id:, start_date:, end_date:)
      time_range = range_from_timeframe(start_date, end_date)
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

    def self.spending_on_primary_category_over_timeframe(category_name:,
                                                         user_id:,
                                                         start_date:,
                                                         end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.primary_category_spending_over_time(category_name, user_id)
        )
      )
    end

    def self.spending_on_detailed_category_over_timeframe(category_name:,
                                                          user_id:,
                                                          start_date:,
                                                          end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.detailed_category_spending_over_time(category_name, user_id)
        )
      )
    end

    def self.spending_on_merchant_over_timeframe(merchant_name:, user_id:, start_date:, end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.merchant_spending_over_time(merchant_name, user_id)
        )
      )
    end

    def self.total_spending_on_all_categories_over_timeframe(user_id:, start_date:, end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.category_totals(user_id)
        )
      )
    end

    def self.spending_over_timeframe(user_id:, start_date:, end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.total_spending_over_time(user_id)
        )
      )
    end

    def self.income_over_timeframe(user_id:, start_date:, end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.total_income_over_time(user_id)
        )
      )
    end

    def self.spending_on_label_over_timeframe(user_id:, label_id:, start_date:, end_date:)
      present_as_hash(
        filter_for_timeframe(
          start_date,
          end_date,
          ::Transaction.label_spending_over_time(label_id, user_id)
        )
      )
    end

    def self.present_as_hash(records)
      records.map do |rec|
        { amount: rec['total'].abs.round(2), month: rec['month'].strftime('%B %Y') }
      end
    end

    def self.filter_for_timeframe(start_date, end_date, records)
      time_range = range_from_timeframe(start_date, end_date)
      records.filter { |record| time_range.cover?(record['month']) }
    end

    def self.range_from_timeframe(start_date, end_date)
      Date.parse(start_date)..Date.parse(end_date)
    end
  end
end

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
      when 'spending_by_category_over_timeframe'
        spending_by_category_over_timeframe(**params)
      when 'income_over_timeframe'
        income_over_timeframe(**params)
      when 'account_balance_history'
        account_balance_history(**params)
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
            proc { |row|
              ::Account::DEBT_ACCOUNT_TYPES.include?(row['account_type'])
            }
          )
        )
      end
        # Remove months where both debts and assets are 0 which is an artifact of loading
        # some months from a file
        .reject { |row| row['assets'] == 0.0 && row['debts'] == 0.0 }
               .concat(mint_data('mint_data/net_worth.json'))
               .group_by { |h| h['month'] }
               .map do |_month, values|
        values.reduce do |memo, value|
          memo['assets'] += value['assets']
          memo['debts'] += value['debts']
          memo
        end
      end
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

    def self.account_balance_history(user_id:, account_id:, start_date:, end_date:)
      time_range = range_from_timeframe(start_date, end_date)
      ::Account.balances_by_month(user_id, account_id)
               .filter { |row| time_range.cover?(row['month']) }
               .map do |row|
        { month:   row['month'].strftime('%B %Y'),
          balance: row['amount'].round(2) }
      end
               .sort_by { |h| Date.strptime(h[:month], '%B %Y') }
    end

    def self.spending_by_category_over_timeframe(user_id:, start_date:, end_date:)
      records = filter_for_timeframe(
        start_date,
        end_date,
        ::Transaction.spending_by_category_over_time(user_id)
      )

      grouped_by_month = records.group_by { |rec| rec['month'].to_date }
      grouped_by_month.flat_map do |month, month_records|
        sorted_categories = month_records.sort_by { |rec| -rec['total'].to_f }
        top_ten = sorted_categories.first(10)
        other_total = sorted_categories.drop(10).sum { |rec| rec['total'].to_f }

        month_str = month.strftime('%B %Y')

        month_data = top_ten.map do |rec|
          {
            month:    month_str,
            category: rec['category'].split('_').map(&:downcase).join(' '),
            total:    rec['total'].to_f.abs.round(2)
          }
        end

        if other_total.positive?
          month_data << {
            month:    month_str,
            category: 'Other',
            total:    other_total.abs.round(2)
          }
        end

        month_data
      end
    end

    def self.present_as_hash(records)
      records.map do |rec|
        { amount: rec['total'].abs.round(2), month: rec['month'].strftime('%B %Y') }
      end
    end

    def self.filter_for_timeframe(start_date, end_date, records)
      time_range = range_from_timeframe(start_date, end_date)
      records.filter { |record| time_range.cover?(record['month'].to_date) }
    end

    def self.range_from_timeframe(start_date, end_date)
      Date.parse(start_date)..Date.parse(end_date)
    end
  end
end

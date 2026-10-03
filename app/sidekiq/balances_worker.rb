# frozen_string_literal: true

class BalancesWorker
  include Sidekiq::Worker

  # All balances before this date will come from static mint data read via
  # JSON file so only fill in months with missing balances after this date
  BALANCE_START_DATE = Date.new(2024, 2, 1)

  def perform
    current_time = Time.current
    ::Account.all.each do |account|
      newest_existing_balance = account.balances.order(created_at: :desc).first

      timestamp = newest_existing_balance.created_at
      next if timestamp.year == current_time.year && timestamp.month == current_time.month

      # rubocop:disable Layout/LineLength
      months_to_create_balance = ((current_time.year * 12) + current_time.month) - ((timestamp.year * 12) + timestamp.month)
      Rails.logger.info("Creating #{months_to_create_balance} months worth of transactions for Account ID: #{account.id}")
      # rubocop:enable Layout/LineLength

      (1..months_to_create_balance).each do |delta|
        new_timestamp = balance_timestamp(timestamp, delta, current_time)
        new_balance = newest_existing_balance.dup
        new_balance.created_at = new_timestamp
        new_balance.interpolated = true
        new_balance.save!
      end
    end
  end

  private

  def balance_timestamp(timestamp, delta, current_time)
    target_month = timestamp.to_date.beginning_of_month.advance(months: delta)
    return current_time if target_month.year == current_time.year && target_month.month == current_time.month

    target_month.end_of_month.end_of_day
  end
end

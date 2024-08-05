# frozen_string_literal: true

class BalancesWorker
  include Sidekiq::Worker
  # All balances before this date will come from static mint data read via
  # JSON file so only fill in months with missing balances after this date
  BALANCE_START_DATE = Date.new(2024, 2, 1)

  # rubocop:disable Layout/LineLength
  def perform
    ::Account.all.each do |account|
      newest_existing_balance = account.balances.order(created_at: :desc).first

      timestamp = newest_existing_balance.created_at
      next unless timestamp.month != DateTime.current.month

      months_to_create_balance = ((DateTime.current.year * 12) + DateTime.current.month) - ((timestamp.year * 12) + timestamp.month)
      Rails.logger.info("Creating #{months_to_create_balance} months worth of transactions for Account ID: #{account.id}")

      (1..months_to_create_balance).each do |delta|
        new_timestamp = timestamp + delta.month
        new_balance = newest_existing_balance.dup
        new_balance.created_at = new_timestamp
        new_balance.interpolated = true
        new_balance.save!
      end
    end
  end
  # rubocop:enable Layout/LineLength
end

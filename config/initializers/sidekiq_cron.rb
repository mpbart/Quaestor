# frozen_string_literal: true

require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      'balances_worker_monthly' => {
        'class' => 'BalancesWorker',
        'cron'  => '0 5 1 * *' # 5am, first day of every month
      }
    )
  end
end

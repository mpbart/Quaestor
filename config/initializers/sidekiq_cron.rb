# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      'balances_worker_monthly' => {
        'class' => 'BalancesWorker',
        'cron'  => '0 0 1 * *' # midnight, first day of every month
      }
    )
  end
end

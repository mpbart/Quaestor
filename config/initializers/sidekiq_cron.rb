# frozen_string_literal: true

require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      'transaction_refresh_nightly' => {
        'class' => 'TransactionRefreshWorker',
        'cron'  => '0 22 * * * America/New_York' # 10pm Eastern, every day
      }
    )
  end
end

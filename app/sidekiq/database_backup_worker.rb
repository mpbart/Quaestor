# frozen_string_literal: true

require 'finance_manager/google_api_client'

class DatabaseBackupWorker
  include Sidekiq::Worker

  def perform(user_id)
    create_local_backup(user_id)
    ::FinanceManager::GoogleApiClient.upload_latest_backup_to_drive(user_id)
    ::FinanceManager::GoogleApiClient.cleanup_old_backups(user_id)
  end

  def create_local_backup(_user_id)
    `#{Rails.root}/bin/backup_db.sh crm_dev`
  end
end

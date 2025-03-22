# frozen_string_literal: true

require 'finance_manager/google_api_client'

class DatabaseBackupWorker
  include Sidekiq::Worker

  def perform
    create_local_backup
    ::FinanceManager::GoogleApiClient.upload_latest_backup_to_drive
    ::FinanceManager::GoogleApiClient.cleanup_old_backups
  end

  def create_local_backup
    `#{Rails.root}/bin/backup_db.sh crm_dev`
  end
end

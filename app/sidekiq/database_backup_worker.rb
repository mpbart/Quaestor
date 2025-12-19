# frozen_string_literal: true

require 'finance_manager/google_api_client'

class DatabaseBackupWorker
  include Sidekiq::Worker
  DB_BACKUP_DIR = "#{Rails.root}/db_backups".freeze

  def perform(user_id)
    create_local_backup
    clean_old_local_backups
    ::FinanceManager::GoogleApiClient.upload_latest_backup_to_drive(user_id)
    ::FinanceManager::GoogleApiClient.cleanup_old_backups(user_id)
  end

  def create_local_backup
    `#{Rails.root}/bin/backup_db.sh crm_dev`
  end

  def clean_old_local_backups
    # Delete all but the newest 5 backups
    total = Dir.entries(DB_BACKUP_DIR)
               .sort { |a, b| b <=> a }
               .filter { |f| f.include?('backup') }
               .drop(5)
               .map { |f| `rm #{DB_BACKUP_DIR}/#{f}` }
    Rails.logger.info("Removed #{total.count} local database backup files")
  end
end

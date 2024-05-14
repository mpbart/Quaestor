# frozen_string_literal: true

class DatabaseBackupWorker
  include Sidekiq::Worker

  def perform
    `#{Rails.root}/bin/backup_db.sh crm_dev`
  end
end

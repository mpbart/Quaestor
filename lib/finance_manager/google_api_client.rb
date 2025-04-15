# frozen_string_literal: true

require 'googleauth/stores/file_token_store'
require 'google/apis/drive_v3'

module FinanceManager
  module GoogleApiClient
    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
    CREDENTIALS_PATH = Rails.root.join('oauth_google_creds.json').freeze
    TOKEN_PATH = Rails.root.join('config', 'google_drive_token.yaml').freeze
    SCOPE = Google::Apis::DriveV3::AUTH_DRIVE
    MAX_BACKUPS_TO_KEEP = 5

    def self.drive_service
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = authorize
      service
    end

    def self.authorize
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = 'default'
      credentials = authorizer.get_credentials(user_id)

      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI)
        puts 'Open the following URL in your browser and authorize the application:'
        puts url
        puts 'Enter the authorization code:'
        code = gets.chomp
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: OOB_URI
        )
      end

      credentials
    end

    def self.store_credentials(code, redirect_uri)
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = 'default'

      authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: redirect_uri
      )
    end

    def self.gdrive_folder_id
      service = drive_service
      response = service.list_files(
        q: "name='db_backups' and mimeType='application/vnd.google-apps.folder' and trashed=false"
      )

      if response.files.empty?
        Rails.logger.error('Unable to find google drive folder db_backups/')
      else
        response.files.first.id
      end
    end

    def self.upload_latest_backup_to_drive
      backup_directory = Rails.root.join('db_backups')
      latest_backup = Dir.glob("#{backup_directory}/*.db").max_by { |f| File.mtime(f) }

      return unless latest_backup

      service = drive_service
      backup_folder_id = gdrive_folder_id

      backup_filename = File.basename(latest_backup)
      file_metadata = {
        name:    backup_filename,
        parents: [backup_folder_id]
      }

      response = service.list_files(
        q: "name='#{backup_filename}' and '#{backup_folder_id}' in parents and trashed=false"
      )

      if response.files.any?
        Rails.logger.warn(
          "Existing database backup file already exists in google drive: #{backup_filename}"
        )
      else
        service.create_file(
          file_metadata,
          upload_source: latest_backup,
          content_type:  'application/octet-stream',
          fields:        'id'
        )
        Rails.logger.info("Uploaded new database backup to google drive: #{backup_filename}")
      end
    end

    def self.cleanup_old_backups
      service = drive_service
      backup_folder_id = gdrive_folder_id

      response = service.list_files(
        q:        "'#{backup_folder_id}' in parents and trashed=false",
        order_by: 'name desc',
        fields:   'files(id, name, createdTime)'
      )

      return unless response.files.count > MAX_BACKUPS_TO_KEEP

      files_to_delete = response.files.drop(MAX_BACKUPS_TO_KEEP)

      files_to_delete.each do |file|
        service.delete_file(file.id)
        Rails.logger.info "Deleted old backup file: #{file.name}"
      end
    end
  end
end

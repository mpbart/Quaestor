# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'
require 'finance_manager/google_api_client'

# Characterization coverage for Sidekiq enqueueing and execution, which had no
# automated coverage before the Rails 8 upgrade.
RSpec.describe 'Sidekiq workers' do
  before do
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all
  end

  after { Sidekiq::Testing.disable! }

  let(:user) { create(:user) }

  describe BalancesWorker do
    it 'can be enqueued' do
      expect { described_class.perform_async }.to change { described_class.jobs.size }.by(1)
    end

    it 'enqueues onto the default queue' do
      described_class.perform_async

      expect(described_class.jobs.last['queue']).to eq('default')
      expect(described_class.jobs.last['class']).to eq('BalancesWorker')
    end

    it 'backfills one interpolated balance per missing month' do
      account = create(:account, user: user)
      create(:balance, account: account, amount: 100, created_at: 2.months.ago)

      expect { described_class.new.perform }
        .to change { account.balances.where(interpolated: true).count }.from(0).to(2)
    end

    it 'interpolates balances from the newest existing balance' do
      account = create(:account, user: user)
      create(:balance, account: account, amount: 100, created_at: 2.months.ago)

      described_class.new.perform

      expect(account.balances.where(interpolated: true).pluck(:amount).uniq).to eq([100.0])
    end

    it 'does nothing when the newest balance is from the current month' do
      account = create(:account, user: user)
      create(:balance, account: account, amount: 100, created_at: Time.current)

      expect { described_class.new.perform }.not_to(change { account.balances.count })
    end
  end

  describe DatabaseBackupWorker do
    it 'can be enqueued with a user id' do
      expect { described_class.perform_async(user.id) }.to change { described_class.jobs.size }.by(1)
      expect(described_class.jobs.last['args']).to eq([user.id])
    end

    it 'runs the backup pipeline in order' do
      worker = described_class.new
      allow(worker).to receive(:create_local_backup)
      allow(worker).to receive(:clean_old_local_backups)
      allow(FinanceManager::GoogleApiClient).to receive(:upload_latest_backup_to_drive)
      allow(FinanceManager::GoogleApiClient).to receive(:cleanup_old_backups)

      worker.perform(user.id)

      expect(worker).to have_received(:create_local_backup).ordered
      expect(worker).to have_received(:clean_old_local_backups).ordered
      expect(FinanceManager::GoogleApiClient)
        .to have_received(:upload_latest_backup_to_drive).with(user.id)
      expect(FinanceManager::GoogleApiClient).to have_received(:cleanup_old_backups).with(user.id)
    end

    it 'uses the db_backups directory under the Rails root' do
      expect(described_class::DB_BACKUP_DIR).to eq("#{Rails.root}/db_backups")
    end
  end
end

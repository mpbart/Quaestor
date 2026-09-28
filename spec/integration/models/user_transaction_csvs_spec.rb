# frozen_string_literal: true

require 'rails_helper'
require 'csv_import/importer'
require 'fileutils'
require 'securerandom'

# Characterization coverage for CSV attachments and CSV import, neither of which
# had automated coverage before the Rails 8 upgrade.
RSpec.describe 'Transaction CSV import', type: :model do
  let(:user) { create(:user) }

  describe 'User#transaction_csvs' do
    it 'stores and reads back an attached CSV' do
      user.transaction_csvs.attach(
        io:           StringIO.new("Date,Description,Amount\n01/15/2023,Weekly shop,-25.50\n"),
        filename:     'transactions.csv',
        content_type: 'text/csv'
      )

      expect(user.transaction_csvs).to be_attached
      expect(user.transaction_csvs.last.filename.to_s).to eq('transactions.csv')
      expect(user.transaction_csvs.last.download).to include('Weekly shop')
      expect(user.transaction_csvs.last.blob.service_name).to eq('test')
    end
  end

  describe 'CsvImport::Importer.process_csv' do
    let!(:expense_category) do
      create(
        :plaid_category,
        primary_category:  'FOOD_AND_DRINK',
        detailed_category: 'FOOD_AND_DRINK_GROCERIES'
      )
    end
    let!(:income_category) do
      create(
        :plaid_category,
        primary_category:  'INCOME',
        detailed_category: 'INCOME_WAGES'
      )
    end

    let(:csv_path) { Rails.root.join('tmp', "spec_csv_#{SecureRandom.hex(8)}.csv").to_s }

    let(:csv_contents) do
      <<~CSV
        Date,Description,Amount,Transaction Type,Category,Labels
        01/15/2023,Weekly shop,-25.50,debit,Groceries,"Food,Home"
        02/20/2023,Refund,4.00,credit,Paycheck,Salary
      CSV
    end

    before { File.write(csv_path, csv_contents) }
    after { FileUtils.rm_f(csv_path) }

    it 'creates one transaction per row' do
      expect { CsvImport::Importer.process_csv(csv_path, user.id) }
        .to change { Transaction.count }.by(2)
    end

    it 'maps description, amount, date, category and labels from the row' do
      CsvImport::Importer.process_csv(csv_path, user.id)

      transaction = Transaction.find_by(description: 'Weekly shop')
      expect(transaction.user_id).to eq(user.id)
      expect(transaction.amount).to eq(25.5)
      # The row is parsed as a UTC midnight and then converted into the app's
      # time zone, so a date-only CSV value lands on the previous evening.
      expect(transaction.date).to eq(Time.zone.parse('2023-01-14 19:00:00'))
      expect(transaction.plaid_category).to eq(expense_category)
      expect(transaction.labels.map(&:name)).to contain_exactly('Food', 'Home')
    end

    it 'sign-flips amounts so debits are positive and credits are negative' do
      CsvImport::Importer.process_csv(csv_path, user.id)

      transaction = Transaction.find_by(description: 'Refund')
      expect(transaction.amount).to eq(-4.0)
      expect(transaction.plaid_category).to eq(income_category)
      expect(transaction.labels.map(&:name)).to eq(['Salary'])
    end

    it 'assigns a distinct identifier to each row' do
      CsvImport::Importer.process_csv(csv_path, user.id)

      ids = Transaction.pluck(:id)
      expect(ids.size).to eq(2)
      expect(ids.uniq.size).to eq(2)
    end

    it 'raises and rolls back every row when a row cannot be mapped' do
      unmappable_path = Rails.root.join('tmp', "spec_csv_bad_#{SecureRandom.hex(8)}.csv").to_s
      File.write(unmappable_path,
                 "Date,Description,Amount,Transaction Type,Category,Labels\n" \
                 "01/15/2023,Weekly shop,-25.50,debit,Not A Real Category,Food\n")

      expect { CsvImport::Importer.process_csv(unmappable_path, user.id) }
        .to raise_error(CsvImport::TransactionCategoryMapper::MappingNotFoundError)
        .and change { Transaction.count }.by(0)
    ensure
      FileUtils.rm_f(unmappable_path)
    end
  end
end

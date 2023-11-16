require 'csv'
require 'base64'
require 'securerandom'
require_relative 'transaction_category_mapper'
require_relative 'constants/mint'

module CsvImport
  class Importer
    class << self
      def process_csv(filename, user_id)
        ActiveRecord::Base.transaction do
          CSV.open(filename, headers: true).each do |row|
            Transaction.create!(
              id:                generate_id,
              user_id:           user_id,
              description:       row['Description'],
              amount:            normalize_amount(row),
              date:              row['Date'],
              plaid_category_id: map_category(row),
              labels:            extract_labels(row),
            )
          end
        end
      end

      def category_mapper
        @category_mapper ||= TransactionCategoryMapper.new
      end

      private

      def normalize_amount(row)
        amount = row['Amount'].to_f
        if row['Transaction Type'] == CsvImport::Constants::Mint::TransactionType::CREDIT && amount > 0.0 ||
            row['Transaction Type'] == CsvImport::Constants::Mint::TransactionType::DEBIT && amount < 0.0
          amount * -1.0 
        else
          amount
        end
      end

      def extract_labels(row)
        row['Labels'].split(',').map{ |l| Label.find_or_create_by(name: l) }
      end

      def map_category(row)
        category = category_mapper[row]
        PlaidCategory.find_by(detailed_category: category.last).id
      end

      def generate_id
        Base64.encode64(SecureRandom.random_bytes(36))[..-2]
      end
    end
  end
end

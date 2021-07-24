require 'csv'
require_relative 'transaction_category_mapper'

module CsvImport
  class Importer

    def process_csv(csv)
      csv.blob.open do |raw_file|
        file = CSV.parse(raw_file, headers: true)
      end
    end

    def category_mapper
      @category_mapper ||= TransactionCategoryMapper.new(source: :mint)
    end

  end
end

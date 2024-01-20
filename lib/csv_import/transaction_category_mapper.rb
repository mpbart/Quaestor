# frozen_string_literal: true

module CsvImport
  class TransactionCategoryMapper
    class MappingNotFoundError < StandardError; end

    def initialize
      @source_mappings = CsvImport::Constants::Mint.new
    end

    def [](transaction)
      category = @source_mappings.map_category(transaction['Category'],
                                               transaction['Description'])

      unless category
        raise MappingNotFoundError,
              "Could not find mapping for category #{transaction['Category']} - #{transaction['Description']}"
      end

      category
    end
  end
end

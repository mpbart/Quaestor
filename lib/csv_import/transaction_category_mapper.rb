module CsvImport
  # Utility class for mapping transaction categories
  # from source (currently only Mint) to plaid 
  class TransactionCategoryMapper
    class MappingNotFoundError < StandardError; end
    
    def initialize(source:)
      @source_mappings = load_source_mappings(source.to_s)
    end

    def [](transaction)
      category = @source_mappings.map_category(transaction.dig('Category'), transaction.dig('Description'))

      raise MappingNotFoundError.new("Could not find mapping for category #{transaction.dig('Category')} - #{ transaction.dig('Description')}") unless category

      category
    end

    private

    def load_source_mappings(source)
      require 'csv_import/constants/' + source
      klass = "CsvImport::Constants::#{source.camelize}".constantize
      klass.new
    end

  end
end

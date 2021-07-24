module CsvImport
  # Utility class for mapping transaction categories
  # from source (currently only Mint) to plaid 
  class TransactionCategoryMapper
    class MappingNotFoundError < StandardError; end
    
    def initialize(source:)
      @source_mappings = load_source_mappings(source.to_s)
    end

    def [](key)
      category = @source_mappings.dig(key)

      raise MappingNotFoundError.new("Could not find mapping for category #{key}") unless category

      category
    end

    private

    def load_source_mappings(source)
      require 'csv_import/constants/' + source
      klass = "CsvImport::Constants::#{source.camelize}".constantize
      klass.mappings
    end

  end
end

module CsvImport
  class TransactionCategoryMapper
    class MappingNotFoundError < StandardError; end
    
    def initialize
      @source_mappings = CsvImport::Constants::Mint.new
    end

    def [](transaction)
      category = @source_mappings.map_category(transaction.dig('Category'), transaction.dig('Description'))

      raise MappingNotFoundError.new("Could not find mapping for category #{transaction.dig('Category')} - #{ transaction.dig('Description')}") unless category

      category
    end
  end
end

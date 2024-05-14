# frozen_string_literal: true

module QueryBuilder
  module PlaidCategories
    def plaid_categories_table
      @plaid_categories_table ||= Arel::Table.new(:plaid_categories)
    end

    def plaid_category_id(value)
      plaid_categories_table[:id].eq(value)
    end
  end
end

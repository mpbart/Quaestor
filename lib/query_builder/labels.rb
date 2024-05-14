# frozen_string_literal: true

module QueryBuilder
  module Labels
    def labels_table
      @labels_table ||= Arel::Table.new(:labels)
    end

    def label_id(value)
      labels_table[:id].eq(value)
    end
  end
end

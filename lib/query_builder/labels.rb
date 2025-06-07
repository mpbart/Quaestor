# frozen_string_literal: true

module QueryBuilder
  module Labels
    def labels_transactions_table
      @labels_transactions_table ||= Arel::Table.new(:labels_transactions)
    end

    def label_id(value)
      subquery = labels_transactions_table.project(labels_transactions_table[:transaction_id])
                                          .where(labels_transactions_table[:label_id].eq(value))

      transactions_table[:id].in(subquery)
    end
  end
end

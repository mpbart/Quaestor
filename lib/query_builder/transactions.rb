# frozen_string_literal: true

module QueryBuilder
  module Transactions
    def transactions_table
      @transactions_table ||= Arel::Table.new(:transactions)
    end

    def q(value)
      transactions_table[:description].matches("%#{value}%")
    end

    def start_date(value)
      transactions_table[:date].gteq(value)
    end

    def end_date(value)
      transactions_table[:date].lteq(value)
    end
  end
end
